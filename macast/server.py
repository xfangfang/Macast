import os
import random
import sys
import logging
import threading

import cherrypy
import portend
from cherrypy._cpserver import Server
from cherrypy.process.plugins import Monitor

from .utils import Setting, XMLPath, SettingProperty, SETTING_DIR
from .plugin import ProtocolPlugin, RendererPlugin, SSDPPlugin
from .protocol import DLNAProtocol, Protocol, DLNAHandler

logger = logging.getLogger("server")
logger.setLevel(logging.DEBUG)


def auto_change_port(fun):
    """See AutoPortServer"""

    def wrapper(self):
        try:
            return fun(self)
        except portend.Timeout as e:
            logger.error(e)
            bind_host, bind_port = self.bind_addr
            if bind_port == 0:
                raise e
            else:
                self.httpserver = None
                self.bind_addr = (bind_host, 0)
                self.start()

    return wrapper


class AutoPortServer(Server):
    """
    The modified Server can give priority to the preset port (Setting.DEFAULT_PORT).
    When the preset port or the port in the configuration file cannot be used,
    using the port randomly assigned by the system
    """

    @auto_change_port
    def start(self):
        super(AutoPortServer, self).start()

    @auto_change_port
    def _start_http_thread(self):
        try:
            self.httpserver.start()
        except KeyboardInterrupt:
            self.bus.log('<Ctrl-C> hit: shutting down HTTP server')
            self.interrupt = sys.exc_info()[1]
            self.bus.exit()
        except SystemExit:
            self.bus.log('SystemExit raised: shutting down HTTP server')
            self.interrupt = sys.exc_info()[1]
            self.bus.exit()
            raise
        except Exception:
            self.interrupt = sys.exc_info()[1]
            if 'WinError 10013' in str(self.interrupt):
                self.bus.log('Error in HTTP server: WinError 10013')
                raise portend.Timeout
            else:
                self.bus.log('Error in HTTP server: shutting down',
                             traceback=True, level=40)
                self.interrupt = sys.exc_info()[1]
                self.bus.exit()
                raise


class Service:

    def __init__(self, renderer, protocol):
        self.thread = None
        # Replace the default server
        cherrypy.server.unsubscribe()
        cherrypy.server = AutoPortServer()
        cherrypy.server.bind_addr = ('0.0.0.0', Setting.get_port())
        cherrypy.server.subscribe()
        # start plugins
        self.ssdp_plugin = SSDPPlugin(cherrypy.engine)
        self.ssdp_plugin.subscribe()
        self._renderer = renderer
        self.renderer_plugin = RendererPlugin(cherrypy.engine, renderer)
        self.renderer_plugin.subscribe()
        self._protocol = protocol
        self.protocol_plugin = ProtocolPlugin(cherrypy.engine, protocol)
        self.protocol_plugin.subscribe()
        self.ssdp_monitor_counter = 0  # restart ssdp every 30s
        self.ssdp_monitor = Monitor(cherrypy.engine, self.notify, 3, name="SSDP_NOTIFY_THREAD")
        self.ssdp_monitor.subscribe()
        cherrypy.config.update({
            'log.screen': False,
            'log.access_file': os.path.join(SETTING_DIR, 'macast.log'),
            'log.error_file': os.path.join(SETTING_DIR, 'macast.log'),
        })
        # cherrypy.engine.autoreload.files.add(Setting.setting_path)
        cherrypy_config = {
            '/dlna': {
                'tools.staticdir.root': XMLPath.BASE_PATH.value,
                'tools.staticdir.on': True,
                'tools.staticdir.dir': "xml"
            },
            '/assets': {
                'tools.staticdir.root': XMLPath.BASE_PATH.value,
                'tools.staticdir.on': True,
                'tools.staticdir.dir': "assets"
            },
            '/': {
                'request.dispatch': cherrypy.dispatch.MethodDispatcher(),
                'tools.response_headers.on': True,
                'tools.response_headers.headers':
                    [('Content-Type', 'text/xml; charset="utf-8"'),
                     ('Server', Setting.get_server_info())],
            }
        }

        self.cherrypy_application = cherrypy.tree.mount(self.protocol.handler, '/', config=cherrypy_config)
        cherrypy.engine.signals.subscribe()

    @property
    def renderer(self):
        return self._renderer

    @renderer.setter
    def renderer(self, value):
        self._renderer = value
        self.renderer_plugin.set_renderer(self._renderer)

    @property
    def protocol(self):
        return self._protocol

    @protocol.setter
    def protocol(self, value: Protocol):
        self.stop()
        self._protocol = value
        self.protocol_plugin.set_protocol(self._protocol)
        self.cherrypy_application.root = self._protocol.handler
        self._protocol.handler.reload()

    def notify(self):
        """ssdp do notify
        Using cherrypy builtin plugin Monitor to trigger this method
        see also: plugin.py -> class SSDPPlugin -> notify
        """
        self.ssdp_monitor_counter += 1
        if Setting.is_ip_changed() or self.ssdp_monitor_counter == 10:
            self.ssdp_monitor_counter = 0
            cherrypy.engine.publish('ssdp_update_ip')
        cherrypy.engine.publish('ssdp_notify')

    def run(self):
        """Start macast thread
        """
        cherrypy.engine.start()
        # update current port
        _, port = cherrypy.server.bound_addr
        logger.info("Server current run on port: {}".format(port))
        if port != Setting.get(SettingProperty.ApplicationPort, 0):
            # todo 验证正确性
            usn = Setting.get_usn(refresh=True)
            logger.error("Change usn to: {}".format(usn))
            Setting.set(SettingProperty.ApplicationPort, port)
            name = "Macast({0:04d})".format(random.randint(0, 9999))
            logger.error("Change name to: {}".format(name))
            Setting.set_temp_friendly_name(name)
            self.protocol.handler.reload()
            cherrypy.engine.publish('ssdp_update_ip')
        # service started
        cherrypy.engine.block()
        # service stopped
        logger.info("Service stopped")

    def stop(self):
        """Stop macast thread
        """
        Setting.stop_service()
        if self.thread is not None:
            self.thread.join()

    def run_async(self):
        if Setting.is_service_running():
            return
        self.thread = threading.Thread(target=self.run, name="SERVICE_THREAD")
        self.thread.start()
