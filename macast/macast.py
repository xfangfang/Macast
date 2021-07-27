# Copyright (c) 2021 by xfangfang. All Rights Reserved.

import os
import re
import time
import json
import requests
import cherrypy
import logging
import subprocess
import threading
from cherrypy.process.plugins import Monitor

from .utils import loadXML, XMLPath, PORT, Setting
from .plugin import SSDPPlugin, MPVPlugin

logging.getLogger("cherrypy").propagate = False
logger = logging.getLogger("main")


@cherrypy.expose
class DLNAHandler:
    """Receiving requests from DLNA client
    and communicating with the RenderPlugin thread
    see also: plugin.py -> class RenderPlugin
    """

    def __init__(self):
        self.description = loadXML(XMLPath.DESCRIPTION.value).format(
            friendly_name=Setting.getFriendlyName(),
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
            res = cherrypy.engine.publish('call_render', rawbody).pop()
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


def notify():
    """ssdp do notify
    Using cherrypy builtin plugin Monitor to trigger this method
    see also: plugin.py -> class SSDPPlugin -> notify
    """
    if Setting.isIPChanged():
        cherrypy.engine.publish('ssdp_updateip')
    cherrypy.engine.publish('ssdp_notify')


def run():
    """Start macast thread
    """
    Setting.load()
    ssdpPlugin = SSDPPlugin(cherrypy.engine)
    ssdpPlugin.subscribe()
    mpvPlugin = MPVPlugin(cherrypy.engine)
    mpvPlugin.subscribe()
    ssdpMonitor = Monitor(cherrypy.engine, notify, 3)
    ssdpMonitor.subscribe()
    cherrypy_config = {
        'global': {
            'server.socket_host': '0.0.0.0',
            'server.socket_port': PORT,
            'log.screen': False,
            'log.access_file': "",
            'log.error_file': ""
        },
        '/dlna': {
            'tools.staticdir.root': XMLPath.BASE_PATH.value,
            'tools.staticdir.on': True,
            'tools.staticdir.dir': "xml"
        },
        '/': {
            'request.dispatch':
            cherrypy.dispatch.MethodDispatcher(),
            'tools.response_headers.on':
            True,
            'tools.response_headers.headers':
            [('Content-Type', 'text/xml; charset="utf-8"'),
             ('Server',
              '{}/{} UPnP/1.0 Macast/{}'.format(Setting.getSystem(),
                                                Setting.getSystemVersion(),
                                                Setting.getVersion()))],
        }
    }
    cherrypy.quickstart(DLNAHandler(), '/', config=cherrypy_config)
    ssdpPlugin.unsubscribe()
    mpvPlugin.unsubscribe()
    ssdpMonitor.unsubscribe()
    logger.error("Cherrypy stopped")


def stop():
    """Stop macast thread
    """
    while cherrypy.engine.state != cherrypy.engine.states.STARTED:
        time.sleep(0.5)
    cherrypy.engine.exit()


if __name__ == '__main__':
    run()
