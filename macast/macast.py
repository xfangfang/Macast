# Copyright (c) 2021 by xfangfang. All Rights Reserved.

import re
import cherrypy
import portend
import logging
from cherrypy.process.plugins import Monitor
from cherrypy._cpserver import Server

from .utils import loadXML, XMLPath, Setting, SettingProperty
from .plugin import SSDPPlugin, RendererPlugin
from .renderer import Renderer

logger = logging.getLogger("main")
logger.setLevel(logging.ERROR)


def auto_change_port(start):
    """See AutoPortServer"""

    def wrapper(self):
        try:
            return start(self)
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


@cherrypy.expose
class DLNAHandler:
    """Receiving requests from DLNA client
    and communicating with the RenderPlugin thread
    see also: plugin.py -> class RenderPlugin
    """

    def __init__(self):
        self.description = loadXML(XMLPath.DESCRIPTION.value).format(
            friendly_name=Setting.get_friendly_name(),
            manufacturer="xfangfang",
            manufacturer_url="https://github.com/xfangfang",
            model_description="AVTransport Media Renderer",
            model_name="Macast",
            model_url="https://xfangfang.github.io/Macast",
            model_number=Setting.getVersion(),
            uuid=Setting.getUSN()).encode()

    def GET(self, param=None):
        if param == 'description.xml':
            return self.description
        cherrypy.response.headers['Content-Type'] = 'text/plain'
        return "hello world {}".format(param).encode()

    def POST(self, service, param):
        if param == 'action':
            length = cherrypy.request.headers['Content-Length']
            rawbody = cherrypy.request.body.read(int(length))
            logger.debug(rawbody)
            res = cherrypy.engine.publish('call_render', rawbody).pop()
            cherrypy.response.headers['EXT'] = ''
            logger.debug(res)
            return res
        return b''

    def SUBSCRIBE(self, service="", param=""):
        """DLNA/UPNP event subscribe
        """
        if param == 'event':
            SID = cherrypy.request.headers.get('SID')
            CALLBACK = cherrypy.request.headers.get('CALLBACK')
            TIMEOUT = cherrypy.request.headers.get('TIMEOUT')
            TIMEOUT = TIMEOUT if TIMEOUT is not None else 'Second-1800'
            TIMEOUT = int(TIMEOUT.split('-')[-1])
            if SID:
                logger.error("RENEW SUBSCRIBE:!!!!!!!" + service)
                res = cherrypy.engine.publish(
                    'renew_subscribe', SID, TIMEOUT).pop()
                if res != 200:
                    logger.error("RENEW SUBSCRIBE: cannot find such sid.")
                    raise cherrypy.HTTPError(status=res)
                cherrypy.response.headers['SID'] = SID
                cherrypy.response.headers['TIMEOUT'] = TIMEOUT
            elif CALLBACK:
                logger.error("ADD SUBSCRIBE:!!!!!!!" + service)
                suburl = re.findall("<(.*?)>", CALLBACK)[0]
                res = cherrypy.engine.publish(
                    'add_subscribe', service, suburl, TIMEOUT).pop()
                cherrypy.response.headers['SID'] = res['SID']
                cherrypy.response.headers['TIMEOUT'] = res['TIMEOUT']
            else:
                logger.error("SUBSCRIBE: cannot find sid and callback.")
                raise cherrypy.HTTPError(status=412)
        return b''

    def UNSUBSCRIBE(self, service, param):
        """DLNA/UPNP event unsubscribe
        """
        if param == 'event':
            SID = cherrypy.request.headers.get('SID')
            if SID:
                logger.error("REMOVE SUBSCRIBE:!!!!!!!" + service)
                res = cherrypy.engine.publish('remove_subscribe', SID).pop()
                if res != 200:
                    raise cherrypy.HTTPError(status=res)
                return b''
        logger.error("UNSUBSCRIBE: error 412.")
        raise cherrypy.HTTPError(status=412)


class Service:

    def __init__(self, renderer=Renderer()):
        Setting.load()
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
        self.ssdp_monitor = Monitor(cherrypy.engine, self.notify, 3, name="SSDP_NOTIFY_THREAD")
        self.ssdp_monitor.subscribe()
        cherrypy.config.update({
            'log.screen': False,
            'log.access_file': "",
            'log.error_file': "",
        })
        cherrypy_config = {
            '/dlna': {
                'tools.staticdir.root': XMLPath.BASE_PATH.value,
                'tools.staticdir.on': True,
                'tools.staticdir.dir': "xml"
            },
            '/': {
                'request.dispatch': cherrypy.dispatch.MethodDispatcher(),
                'tools.response_headers.on': True,
                'tools.response_headers.headers':
                    [('Content-Type', 'text/xml; charset="utf-8"'),
                     ('Server', Setting.get_server_info())],
            }
        }

        cherrypy.tree.mount(DLNAHandler(), '/', config=cherrypy_config)
        cherrypy.engine.signals.subscribe()

    @property
    def renderer(self):
        return self._renderer

    @renderer.setter
    def renderer(self, value):
        self.renderer_plugin.stop()
        self.renderer_plugin.unsubscribe()
        self._renderer = value
        self.renderer_plugin = RendererPlugin(cherrypy.engine, self._renderer)
        self.renderer_plugin.subscribe()

    def notify(self):
        """ssdp do notify
        Using cherrypy builtin plugin Monitor to trigger this method
        see also: plugin.py -> class SSDPPlugin -> notify
        """
        if Setting.is_ip_changed():
            cherrypy.engine.publish('ssdp_update_ip')
        cherrypy.engine.publish('ssdp_notify')

    def run(self):
        """Start macast thread
        """
        cherrypy.engine.start()
        # update current port
        _, port = cherrypy.server.bound_addr
        logger.info("Server current run on port: {}".format(port))
        Setting.set(SettingProperty.ApplicationPort, port)
        cherrypy.engine.publish('ssdp_update_ip')
        # service started
        cherrypy.engine.block()
        # service stopped
        logger.info("Service stopped")

    def stop(self):
        """Stop macast thread
        """
        Setting.stop_service()


if __name__ == '__main__':
    Service().run()
