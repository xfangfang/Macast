# Copyright (c) 2021 by xfangfang. All Rights Reserved.

import os
import re
import time
import rumps
import json
import requests
import gettext
import cherrypy
import logging
import subprocess
import threading
from cherrypy.process.plugins import Monitor
from utils import loadXML, XMLPath, PORT, NAME, Setting, SYSTEM, SYSTEM_VERSION
from plugin import SSDPPlugin, MPVPlugin


logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

try:
    locale = Setting.getLocale()
    lang = gettext.translation('macast', localedir='i18n', languages=[locale])
    lang.install()
    logger.error("Loading Language: {}".format(locale))
except Exception as e:
    _ = gettext.gettext
    logger.error("Loading Default Language en_US")



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

def startCherrypy():
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
    cherrypy.quickstart(DLNAHandler(), '/', config = cherrypy_config)
    ssdpPlugin.unsubscribe()
    mpvPlugin.unsubscribe()
    ssdpMonitor.unsubscribe()
    logger.error("Cherrypy stopped")

class Macast(rumps.App):
    def __init__(self):
        super(Macast, self).__init__("Macast",icon='assets/menu.png', title="", template=True, quit_button=None)
        self.thread = None
        self.running = False
        self.startCast()
        self.menu = [
            rumps.MenuItem(_("pause"), callback=self.toggle),
            None,
            [
                rumps.MenuItem(_("Setting")),
                [
                    rumps.MenuItem("IP: {}".format(Setting.getIP())),
                    rumps.MenuItem("Macast (v{})".format(Setting.getVersion())),
                    rumps.MenuItem(_("Check for updates"), callback=self.checkUpdate),
                    rumps.MenuItem(_("About"), callback=self.about),
                ]
            ]
        ]
        rumps.debug_mode(True)
        threading.Thread(target=self.checkUpdate, kwargs={'verbose': False, 'sender': None}).start()

    def stopCast(self):
        while cherrypy.engine.state != cherrypy.engine.states.STARTED:
            time.sleep(0.5)
        cherrypy.engine.exit()
        self.thread.join()
        self.running = False

    def startCast(self):
        if self.running:
            return
        self.thread = threading.Thread(target=startCherrypy, args=())
        self.thread.start()
        self.running = True

    def checkUpdate(self, sender, verbose=True):
        try:
            res = requests.get('https://api.github.com/repos/xfangfang/Macast/releases/latest').text
            res = json.loads(res)
            logger.debug("tag_name: {}".format(res['tag_name']))
            onlineVersion = re.findall(r'(\d+\.*\d+)', res['tag_name'])[0]
            if float(Setting.getVersion()) < float(onlineVersion):
                rumps.notification(_("New Update {}").format(res['tag_name']), "", "opening browser")
                subprocess.run(['open', 'https://github.com/xfangfang/Macast/releases/latest'])
            else:
                if verbose:
                    rumps.alert(_("You're up to date."))
        except Exception as e:
            logger.error("get update info error: {}".format(e))

    def about(self, sender):
        subprocess.run(['open', 'https://github.com/xfangfang/Macast'])

    def toggle(self, sender):
        if self.running:
            sender.title = _('start')
            self.stopCast()
        else:
            sender.title = _('pause')
            self.startCast()

    @rumps.clicked(_('quit'))
    def clean_up_before_quit(self, _):
        if self.running:
            self.stopCast()
        rumps.quit_application()

if __name__ == '__main__':
    Macast().run()
    # startCherrypy()
