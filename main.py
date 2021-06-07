# Copyright (c) 2021 by xfangfang. All Rights Reserved.

import re
import cherrypy
import logging
from cherrypy.process.plugins import Monitor

from utils import loadXML, XMLPath, PORT, NAME, Setting, SYSTEM, SYSTEM_VERSION
from plugin import SSDPPlugin, MPVPlugin


logger = logging.getLogger()
logger.setLevel(logging.ERROR)

@cherrypy.expose
class DLNAHandler:
    def __init__(self):
        self.description = loadXML(XMLPath.DESCRIPTION.value).format(
            friendly_name = NAME,
            manufacturer = "xfangfang",
            manufacturer_url = "https://github.com/xfangfang",
            model_description = "Media Renderer on your MAC",
            model_name = NAME,
            model_url = "https://xfangfang.github.io/dlna-media-render",
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

if __name__ == '__main__':

    Setting.load()
    SSDPPlugin(cherrypy.engine).subscribe()
    MPVPlugin(cherrypy.engine).subscribe()
    Monitor(cherrypy.engine, notify, 3).subscribe()
    cherrypy_config = {
        'global':{
            'server.socket_host' : '0.0.0.0',
            'server.socket_port' : PORT,},
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

    server = DLNAHandler()
    cherrypy.quickstart(server, '/', config = cherrypy_config)
