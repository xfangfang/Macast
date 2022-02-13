import os
import random
import sys
import logging
import threading

import cherrypy
import portend
from cherrypy._cpserver import Server
from cherrypy.process.plugins import Monitor

from .utils import Setting, XMLPath, SettingProperty
from .plugin import ProtocolPlugin, RendererPlugin, SSDPPlugin, ToolPlugin
from .protocol import Protocol

logger = logging.getLogger("server")


def auto_change_port(fun):
    """See AutoPortServer"""

    def wrapper(self: Server):
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
                # port is free but cannot use
                # check your hyper-v setting
                self.bus.log('Error in HTTP server: WinError 10013')
                raise portend.Timeout
            else:
                self.bus.log('Error in HTTP server: shutting down',
                             traceback=True, level=40)
                self.interrupt = sys.exc_info()[1]
                self.bus.exit()
                raise


class Service:

    def __init__(self, renderer, protocol, tool=None):
        if tool is None:
            tool = []

        # global log config
        log_level = Setting.setup_logger()

        self.thread = None
        # Replace the default server
        cherrypy.server.unsubscribe()
        cherrypy.server = AutoPortServer()
        cherrypy.server.bind_addr = ('0.0.0.0', Setting.get_port())
        cherrypy.server.subscribe()
        # start plugins
        self.ssdp_plugin = SSDPPlugin(25)
        self.ssdp_plugin.subscribe()
        self._renderer = renderer
        self.renderer_plugin = RendererPlugin(30, renderer)
        self.renderer_plugin.subscribe()
        self._protocol = protocol
        self.protocol_plugin = ProtocolPlugin(27, protocol)
        self.protocol_plugin.subscribe()
        self.tool_plugin = ToolPlugin(29, tool)
        self.tool_plugin.subscribe()
        self.ip_monitor = Monitor(cherrypy.engine, self.update_ip, 5, name="IP_MONITOR_THREAD")
        self.ip_monitor.subscribe()

        # todo remove cherrypy.autoreload
        # cherrypy.autoreload

        cherrypy.config.update({
            'server.thread_pool': 1
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

    @staticmethod
    def update_ip():
        if Setting.is_ip_changed():
            cherrypy.engine.publish('update_ip')

    @property
    def renderer(self):
        return self._renderer

    @renderer.setter
    def renderer(self, value):
        """
        Change the renderer which server are using

        ATTENTION: This Method will stop the server
        :param value:
        :return:
        """
        if Setting.is_service_running():
            Setting.stop_service()
        self._renderer = value
        self.renderer_plugin.renderer = self._renderer

    @property
    def protocol(self):
        return self._protocol

    @protocol.setter
    def protocol(self, value: Protocol):
        """
        Change the protocol which server are using

        ATTENTION: This Method will stop the server
        :param value:
        :return:
        """
        if Setting.is_service_running():
            Setting.stop_service()
        self._protocol = value
        self.protocol_plugin.protocol = self._protocol
        self.cherrypy_application.root = self._protocol.handler
        self._protocol.handler.reload()

    def run(self):
        """Start macast thread
        """
        cherrypy.engine.start()
        # update current port
        _, port = cherrypy.server.bound_addr
        logger.info("Server current run on port: {}".format(port))
        if port != Setting.get_port():
            # todo 验证正确性
            usn = Setting.get_usn(refresh=True)
            logger.info("Change usn to: {}".format(usn))
            Setting.set(SettingProperty.ApplicationPort, port)
            name = "Macast({0:04d})".format(random.randint(0, 9999))
            logger.info("Change name to: {}".format(name))
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


class SettingService:

    def __init__(self):
        self.thread = None
        self.setting_server = AutoPortServer()
        self.setting_server.bind_addr = ('localhost', Setting.get_setting_port())

    def stop(self):
        """ Stop macast setting http server
        :return:
        """
        if self.thread is None:
            logger.warning("Macast setting http server is not started yet")
            return
        self.thread.join()
        self.thread = None

    def run(self):
        """ Starting in another thread will not block cherrypy
        :return:
        """
        if self.thread is not None:
            logger.warning("Macast setting http server is already started")
            return
        self.thread = threading.Thread(target=self._run, name="SETTING_THREAD", daemon=True)
        self.thread.start()

    def _run(self):
        """ Start macast setting http server
        :return:
        """

        logger.info(f'Start macast setting http server at http://localhost:{Setting.get_setting_port()}')

        self.setting_server.start()
        _, port = self.setting_server.bound_addr
        if port != Setting.get_setting_port():
            Setting.set(SettingProperty.Macast_Setting_Port, port)
            logger.warning(f"Change setting http server port to {port}")
