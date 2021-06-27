# Copyright (c) 2021 by xfangfang. All Rights Reserved.

import os
import re
import sys
import json
import logging
import macast
import cherrypy
import gettext
import requests
import threading
import subprocess
from abc import abstractmethod

logger = logging.getLogger("Macast")
logger.setLevel(logging.DEBUG)

try:
    locale = macast.Setting.getLocale()
    lang = gettext.translation('macast', localedir='i18n', languages=[locale])
    lang.install()
    logger.error("Macast Loading Language: {}".format(locale))
except Exception as e:
    _ = gettext.gettext
    logger.error("Macast Loading Default Language en_US")


class Macast(object):
    def init(self):
        self.thread = None
        self.running = False
        macast.Setting.load()
        self.startCast()
        self.setting_check = macast.Setting.get(macast.SettingProperty.checkUpdate, 1)
        self.setting_player_size = macast.Setting.get(macast.SettingProperty.PlayerSize, 1)
        self.setting_player_position = macast.Setting.get(macast.SettingProperty.PlayerPosition, 2)
        self.setting_player_hw = macast.Setting.get(macast.SettingProperty.PlayerHW, 1)
        if self.setting_check:
            threading.Thread(target = self.checkUpdate, kwargs={'verbose': False}).start()
        logger.debug("Macast APP started")

    @abstractmethod
    def alert(self, content):
        pass

    @abstractmethod
    def notification(self, title, content):
        pass

    @abstractmethod
    def openBrowser(self, url):
        pass

    @abstractmethod
    def newUpdate(self, version):
        pass

    def about(self):
        self.openBrowser('https://github.com/xfangfang/Macast')

    def stopCast(self):
        macast.stop()
        self.thread.join()
        self.running = False
        cherrypy.engine.unsubscribe('mpv_start', self.mpv_start)
        cherrypy.engine.unsubscribe('mpv_av_stop', self.mpv_av_stop)
        cherrypy.engine.unsubscribe('mpv_av_uri', self.mpv_av_uri)
        cherrypy.engine.unsubscribe('ssdp_updateip', self.mpv_av_uri)

    def startCast(self):
        if self.running:
            return
        self.thread = threading.Thread(target=macast.run, args=())
        self.thread.start()
        self.running = True
        cherrypy.engine.subscribe('mpv_start', self.mpv_start)
        cherrypy.engine.subscribe('mpv_av_stop', self.mpv_av_stop)
        cherrypy.engine.subscribe('mpv_av_uri', self.mpv_av_uri)
        cherrypy.engine.subscribe('ssdp_updateip', self.ssdp_updateip)

    def ssdp_updateip(self):
        logger.debug("ssdp_updateip")

    def mpv_start(self):
        logger.debug("mpv_start")

    def mpv_av_stop(self):
        logger.debug("mpv_stop")

    def mpv_av_uri(self, uri):
        logger.debug("mpv_av_uri: "+uri)


    def checkUpdate(self, verbose = True):
        try:
            res = requests.get('https://api.github.com/repos/xfangfang/Macast/releases/latest').text
            res = json.loads(res)
            logger.debug("tag_name: {}".format(res['tag_name']))
            onlineVersion = re.findall(r'(\d+\.*\d+)', res['tag_name'])[0]
            if float(macast.Setting.getVersion()) < float(onlineVersion):
                self.newUpdate(res['tag_name'])
            else:
                if verbose:
                    self.alert(_("You're up to date."))
        except Exception as e:
            logger.error("get update info error: {}".format(e))

    def toggle(self):
        if self.running:
            self.stopCast()
        else:
            self.startCast()

    def quit(self):
        if self.running:
            self.stopCast()

if sys.platform == 'darwin':
    import rumps
    from AppKit import NSPasteboard, NSArray
    class Macast_darwin(rumps.App, Macast):
        def __init__(self):
            super(Macast_darwin, self).__init__("Macast",icon='assets/menu.png', title="", template=True, quit_button=None)
            macast.Setting.setMpvPath(os.path.abspath('bin/MacOS/mpv'))
            self.init()
            self._buildMenu()
            rumps.debug_mode(True)

        def _buildMenu(self):
            self.toggleItem = rumps.MenuItem(_("Stop Cast"), key="p", callback=self.toggle)
            self.ipItem = rumps.MenuItem("IP: {}".format(macast.Setting.getIP()))
            self.playerPositionItem = rumps.MenuItem(_("Player Position"))
            self.playerSizeItem = rumps.MenuItem(_("Player Size"))
            self.playerHWItem = rumps.MenuItem(_("Hardware Decode"))
            self.autoCheckUpdateItem = rumps.MenuItem(_("Auto check updates"), self.autoCheckUpdate)
            self.menu = [
                self.toggleItem ,
                None,
                [
                    rumps.MenuItem(_("Setting")),
                    [
                        self.ipItem,
                        rumps.MenuItem("Macast (v{})".format(macast.Setting.getVersion())),
                        None,
                        [
                            self.playerPositionItem,
                            self._buildMenuItems([_("LeftTop"), _("LeftBottom"), _("RightTop"), _("RightBottom"), _("Center")], self.playerPosition)
                        ],
                        [
                            self.playerSizeItem,
                            self._buildMenuItems([_("Small"), _("Normal"), _("Large"), _("Auto"), _("Fullscreen")], self.playerSize)
                        ],
                        [
                            self.playerHWItem,
                            self._buildMenuItems([_("Hardware Decode"), _("Force Dedicated GPU")], self.playerHW)
                        ],
                        None,
                        self.autoCheckUpdateItem,
                        rumps.MenuItem(_("Start on login")),
                        rumps.MenuItem(_("Check for updates"), callback=self.check),
                        rumps.MenuItem(_("About"), callback=self.about),
                    ]
                ],
                rumps.MenuItem(_("Quit"), key="q", callback=self.quit),
            ]
            self.autoCheckUpdateItem.state = self.setting_check
            self.playerPositionItem.items()[self.setting_player_position][1].state = True
            self.playerSizeItem.items()[self.setting_player_size][1].state = True
            if self.setting_player_hw == 0:
                self.playerHWItem.items()[1][1].set_callback(None)
            else:
                self.playerHWItem.items()[0][1].state = True
            self.playerHWItem.items()[1][1].state = (self.setting_player_hw == 2)

        def _buildMenuItems(self, titles, callback):
            items = []
            for index, title in enumerate(titles):
                item = rumps.MenuItem(title, callback=callback)
                item.index = index
                items.append(item)
            return items

        def playerPosition(self, sender):
            for key, item in self.playerPositionItem.iteritems():
                item.state = False
            sender.state = True
            macast.Setting.set(macast.SettingProperty.PlayerPosition, sender.index)
            self.notification(_("Reload MPV"), _("please wait"))
            cherrypy.engine.publish('reloadRender')

        def playerHW(self, sender):
            sender.state = not sender.state
            if sender.index == 0:
                if sender.state:
                    # Default Hardware Decode
                    macast.Setting.set(macast.SettingProperty.PlayerHW, 1)
                    self.playerHWItem.items()[1][1].set_callback(self.playerHW)
                else:
                    # Software Decode
                    macast.Setting.set(macast.SettingProperty.PlayerHW, 0)
                    self.playerHWItem.items()[1][1].state = False
                    self.playerHWItem.items()[1][1].set_callback(None)
            elif sender.state:
                # Force Dedicated GPU
                macast.Setting.set(macast.SettingProperty.PlayerHW, 2)
            else:
                # Default Hardware Decode
                macast.Setting.set(macast.SettingProperty.PlayerHW, 1)
            self.notification(_("Reload MPV"), _("please wait"))
            cherrypy.engine.publish('reloadRender')

        def playerSize(self, sender):
            for key, item in self.playerSizeItem.iteritems():
                item.state = False
            sender.state = True
            macast.Setting.set(macast.SettingProperty.PlayerSize, sender.index)
            if sender.index == 3:
                self.playerPosition(self.playerPositionItem.items()[4][1])
            self.notification(_("Reload MPV"), _("please wait"))
            cherrypy.engine.publish('reloadRender')

        def autoCheckUpdate(self, sender):
            sender.state = not sender.state
            macast.Setting.set(macast.SettingProperty.checkUpdate, 1 if sender.state else 0)

        def ssdp_updateip(self):
            logger.debug("ssdp_updateip")
            self.ipItem.title = "IP: {}".format(macast.Setting.getIP())

        def mpv_av_stop(self):
            if self.copyItem != None:
                self.menu.pop(self.copyItem.title)
                self.copyItem = None

        def mpv_av_uri(self, uri):
            logger.debug("mpv_av_uri: " + uri)
            def paste(_):
                pb = NSPasteboard.generalPasteboard()
                pb.clearContents()
                pb.writeObjects_(NSArray.arrayWithObject_(uri))

            self.copyItem = rumps.MenuItem(_("Copy Video URI"), key="c", callback=paste)
            self.menu.insert_after(self.toggleItem.title, self.copyItem)

        def toggle(self, sender):
            super(Macast_darwin, self).toggle()
            if self.running:
                sender.title = _('Stop Cast')
            else:
                sender.title = _('Start Cast')

        def newUpdate(self, version):
            def callback():
                self.openBrowser('https://github.com/xfangfang/Macast/releases/latest')

            self.dialog(_("New Update {}").format(version), callback, ok="Update")

        def openBrowser(self, url):
            subprocess.run(['open', url])

        def alert(self, content):
            rumps.alert(content)

        def notification(self, title, content):
            rumps.notification(title, "", content)

        def dialog(self, content, callback, cancel="Cancel", ok="Ok"):
            res = subprocess.getstatusoutput("""osascript -e 'display dialog "{}" buttons {{"{}", "{}"}}'""".format(
                content, cancel, ok
            ))
            if res[0] == 0 and res[1] == 'button returned:{}'.format(ok):
                callback()

        def check(self, _):
            self.checkUpdate()

        def about(self, _):
            super(Macast_darwin, self).about()

        def quit(self, _):
            super(Macast_darwin, self).quit()
            rumps.quit_application()

else:
    import pystray
    import webbrowser
    from PIL import Image
    class Macast_common(Macast):
        def __init__(self):
            super(Macast_common, self).__init__()
            if os.name == 'nt':
                macast.Setting.setMpvPath(os.path.abspath('bin/mpv.exe'))
            self.init()
            self.icon = pystray.Icon('Macast', Image.open('assets/menu_light.png'), menu = pystray.Menu(
                    pystray.MenuItem("IP: {}".format(macast.Setting.getIP()), None, enabled=False),
                    pystray.MenuItem("Macast (v{})".format(macast.Setting.getVersion()), None, enabled=False),
                    pystray.MenuItem(_("Check for updates"), self.check),
                    pystray.MenuItem(_("About"), self.about),
                    pystray.MenuItem(_('Quit'), self.quit),
                )
            )

        def newUpdate(self, version):
            self.notification(_("New Update {}").format(version), "opening browser")
            self.openBrowser('https://github.com/xfangfang/Macast/releases/latest')

        def openBrowser(self, url):
            webbrowser.open(url)

        def alert(self, content):
            self.icon.notify(message=content, title="Macast")

        def notification(self, title, content):
            self.icon.notify(message=content, title=title)

        def check(self, icon, item):
            self.checkUpdate()

        def about(self, icon, item):
            super(Macast_common, self).about()

        def quit(self, icon, item):
            try:
                icon.remove_notification()
            except Exception as e:
                pass
            super(Macast_common, self).quit()
            self.icon.stop()

        def run(self):
            self.icon.run()

if __name__ == '__main__':
    if sys.platform == 'darwin':
        Macast_darwin().run()
    else:
        Macast_common().run()
