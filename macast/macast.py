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

from .utils import loadXML, XMLPath, PORT, NAME, Setting, SYSTEM, SYSTEM_VERSION
from .plugin import SSDPPlugin, MPVPlugin

logging.getLogger("cherrypy").propagate = False

logger = logging.getLogger()
logger.setLevel(logging.ERROR)


@cherrypy.expose
class DLNAHandler:
    def __init__(self):
        self.description = loadXML(XMLPath.DESCRIPTION.value).format(
            friendly_name = NAME,
            manufacturer = "xfangfang",
            manufacturer_url = "https://github.com/xfangfang",
            model_description = "AVTransport Media Renderer",
            model_name = NAME,
            model_url = "https://xfangfang.github.io/Macast",
            model_number = Setting.getVersion(),
            uuid = Setting.getUSN()).encode()

    def GET(self, param = None):
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
            logger.debug(res)
            return res
        return b''

    def SUBSCRIBE(self, service="", param=""):
        logger.error("SUBSCRIBE:!!!!!!!"+service+param)
        if param == 'event':
            SID = cherrypy.request.headers.get('SID')
            CALLBACK = cherrypy.request.headers.get('CALLBACK')
            if SID:
                 res = cherrypy.engine.publish('renew_subscribe', SID).pop()
                 if res != 200: raise cherrypy.HTTPError(status=res)
            elif CALLBACK:
                suburl = re.findall("<(.*?)>", CALLBACK)[0]
                res = cherrypy.engine.publish('add_subscribe', suburl).pop()
                cherrypy.response.headers['SID'] = res['SID']
                cherrypy.response.headers['TIMEOUT'] = res['TIMEOUT']
        return b''

    def UNSUBSCRIBE(self, service, param):
        if param == 'event':
            SID = cherrypy.request.headers.get('SID')
            if SID:
                res = cherrypy.engine.publish('remove_subscribe', SID).pop()
                if res != 200: raise cherrypy.HTTPError(status=res)
        return b''

def notify():
    if Setting.isIPChanged():
        cherrypy.engine.publish('ssdp_updateip')
    cherrypy.engine.publish('ssdp_notify')

def run():
    Setting.load()
    ssdpPlugin = SSDPPlugin(cherrypy.engine)
    ssdpPlugin.subscribe()
    mpvPlugin = MPVPlugin(cherrypy.engine)
    mpvPlugin.subscribe()
    ssdpMonitor = Monitor(cherrypy.engine, notify, 3)
    ssdpMonitor.subscribe()
    cherrypy_config = {
        'global':{
            'server.socket_host' : '0.0.0.0',
            'server.socket_port' : PORT,
            'log.screen': False,
            'log.access_file': "",
            'log.error_file': ""},
       '/dlna': {
            'tools.staticdir.root' : XMLPath.BASE_PATH.value,
            'tools.staticdir.on' : True,
            'tools.staticdir.dir' : "xml"},
        '/': {
            'request.dispatch': cherrypy.dispatch.MethodDispatcher(),
            'tools.response_headers.on': True,
            'tools.response_headers.headers': [
                ('Content-Type', 'text/xml; charset="utf-8"'),
                ('Server', '{}/{} UPnP/1.0 Macast/{}'.format(SYSTEM, SYSTEM_VERSION, Setting.getVersion()))
            ],
        }
      }
    cherrypy.quickstart(DLNAHandler(), '/', config = cherrypy_config)
    ssdpPlugin.unsubscribe()
    mpvPlugin.unsubscribe()
    ssdpMonitor.unsubscribe()
    logger.error("Cherrypy stopped")

def stop():
    while cherrypy.engine.state != cherrypy.engine.states.STARTED:
        time.sleep(0.5)
    cherrypy.engine.exit()

if __name__ == '__main__':
    run()
