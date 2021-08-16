# Copyright (c) 2021 by xfangfang. All Rights Reserved.

import os
import re
import sys
import json
import logging
import cherrypy
import gettext
import pyperclip
import requests
import threading

import macast
from macast import App, MenuItem, Setting, SettingProperty

logger = logging.getLogger("Macast")
logger.setLevel(logging.DEBUG)

try:
    locale = Setting.getLocale()
    lang = gettext.translation(
        'macast', localedir=Setting.getPath('i18n'), languages=[locale])
    lang.install()
    logger.error("Macast Loading Language: {}".format(locale))
except Exception as e:
    _ = gettext.gettext
    logger.error("Macast Loading Default Language en_US")


class Macast(App):
    def __init__(self):
        self.thread = None
        self.running = False
        Setting.load()
        self.initSetting()
        super(Macast, self).__init__("Macast",
                                     Setting.getPath('assets/menu_light.png'),
                                     self.buildAppMenu()
                                     )
        self.startCast()
        logger.debug("Macast APP started")

    def buildAppMenu(self):
        self.copyItem = None
        self.toggleItem = MenuItem(_("Stop Cast"), self.toggle, key="p")
        self.settingItem = MenuItem(_("Setting"),
                                    children=self.buildSettingMenu())
        self.quitItem = MenuItem(_("Quit"), self.quit, key="q")
        return [
            self.toggleItem,
            None,
            self.settingItem,
            self.quitItem
        ]

    def buildSettingMenu(self):
        self.ipItem = MenuItem("IP: {}".format(Setting.getIP()), enabled=False)
        self.versionItem = MenuItem(
            "Macast (v{})".format(Setting.getVersion()), enabled=False)
        self.autoCheckUpdateItem = MenuItem(_("Auto Check Updates"),
                                            self.autoCheckUpdate,
                                            checked=self.setting_check)
        self.startAtLoginItem = MenuItem(_("Start At Login"),
                                         self.startAtLogin,
                                         checked=self.setting_start_at_login)
        startAtLogin = []
        if sys.platform == 'darwin':
            startAtLogin = [self.startAtLoginItem]
            # Reset StartAtLogin to prevent the user from turning off
            # this option from the system settings
            Setting.setStartAtLogin(self.setting_start_at_login)
        self.playerPositionItem = MenuItem(_("Player Position"),
                                           children=self._buildMenuItemGroup([
                                               _("LeftTop"),
                                               _("LeftBottom"),
                                               _("RightTop"),
                                               _("RightBottom"),
                                               _("Center")
                                           ], self.playerPosition))
        self.playerSizeItem = MenuItem(_("Player Size"),
                                       children=self._buildMenuItemGroup([
                                           _("Small"),
                                           _("Normal"),
                                           _("Large"),
                                           _("Auto"),
                                           _("Fullscreen")
                                       ], self.playerSize))
        self.checkUpdateItem = MenuItem(_("Check For Updates"), self.check)
        self.aboutItem = MenuItem(_("About"), self.about)

        # init setting items
        self.playerPositionItem.items()[
            self.setting_player_position].checked = True
        self.playerSizeItem.items()[
            self.setting_player_size].checked = True
        if sys.platform == 'darwin':
            self.playerHWItem = MenuItem(_("Hardware Decode"),
                                         children=self._buildMenuItemGroup([
                                             _("Hardware Decode"),
                                             _("Force Dedicated GPU")
                                         ], self.playerHW))
            if self.setting_player_hw == 0:
                self.playerHWItem.items()[1].enabled = False
            else:
                self.playerHWItem.items()[0].checked = True
            self.playerHWItem.items()[1].checked = (
                self.setting_player_hw == 2)
        else:
            self.playerHWItem = MenuItem(_("Hardware Decode"),
                                         self.playerHW,
                                         data=0)
            if self.setting_player_hw != 0:
                self.playerHWItem.checked = True

        return [
            self.ipItem,
            self.versionItem,
            None,
            self.playerPositionItem,
            self.playerSizeItem,
            self.playerHWItem,
            None,
            self.autoCheckUpdateItem,
            *startAtLogin,
            None,
            self.checkUpdateItem,
            self.aboutItem
        ]

    def _buildMenuItemGroup(self, titles, callback):
        items = []
        for index, title in enumerate(titles):
            item = MenuItem(title, callback, data=index)
            items.append(item)
        return items

    def playerPosition(self, item):
        for i in self.playerPositionItem.items():
            i.checked = False
        item.checked = True
        Setting.set(SettingProperty.PlayerPosition, item.data)
        if self.copyItem is not None:
            self.notification(_("Reload Player"),
                              _("please wait"),
                              sound=False)
        cherrypy.engine.publish('reloadRender')

    def playerHW(self, item):
        item.checked = not item.checked
        if item.data == 0:
            if item.checked:
                # Default Hardware Decode
                Setting.set(SettingProperty.PlayerHW, 1)
                if sys.platform == 'darwin':
                    self.playerHWItem.items()[1].enabled = True
            else:
                # Software Decode
                Setting.set(SettingProperty.PlayerHW, 0)
                if sys.platform == 'darwin':
                    self.playerHWItem.items()[1].checked = False
                    self.playerHWItem.items()[1].enabled = False
        elif item.checked:
            # Force Dedicated GPU
            Setting.set(SettingProperty.PlayerHW, 2)
        else:
            # Default Hardware Decode
            Setting.set(SettingProperty.PlayerHW, 1)
        if self.copyItem is not None:
            self.notification(_("Reload Player"),
                              _("please wait"),
                              sound=False)
        cherrypy.engine.publish('reloadRender')

    def playerSize(self, item):
        for i in self.playerSizeItem.items():
            i.checked = False
        item.checked = True
        Setting.set(SettingProperty.PlayerSize, item.data)
        if item.data == 3:
            # set player position to center
            for i in self.playerPositionItem.items():
                i.checked = False
            self.playerPositionItem.items()[4].checked = True
            Setting.set(SettingProperty.PlayerPosition, 4)
        if self.copyItem is not None:
            self.notification(_("Reload Player"),
                              _("please wait"),
                              sound=False)
        cherrypy.engine.publish('reloadRender')

    def initSetting(self):
        self.setting_start_at_login = Setting.get(
            SettingProperty.StartAtLogin, 0)
        self.setting_check = Setting.get(
            SettingProperty.CheckUpdate, 1)
        self.setting_player_size = Setting.get(
            SettingProperty.PlayerSize, 1)
        self.setting_player_position = Setting.get(
            SettingProperty.PlayerPosition, 2)
        self.setting_player_hw = Setting.get(
            SettingProperty.PlayerHW, 1)
        if self.setting_check:
            threading.Thread(target=self.checkUpdate,
                             kwargs={
                                 'verbose': False
                             }).start()

    def initPlatformDarwin(self):
        Setting.setMpvPath(os.path.abspath('bin/MacOS/mpv'))

    def initPlatformWin32(self):
        Setting.setMpvPath(Setting.getPath('bin/mpv.exe'))

    def newUpdate(self, version):
        def callback():
            self.openBrowser(
                'https://github.com/xfangfang/Macast/releases/latest')

        self.dialog(_("Macast New Update {}").format(version),
                    callback,
                    ok="Update")

    def about(self, _):
        self.openBrowser('https://github.com/xfangfang/Macast')

    def stopCast(self):
        macast.stop()
        self.thread.join()
        self.running = False
        cherrypy.engine.unsubscribe('mpv_error', self.mpv_error)
        cherrypy.engine.unsubscribe('mpv_start', self.mpv_start)
        cherrypy.engine.unsubscribe('mpv_av_stop', self.mpv_av_stop)
        cherrypy.engine.unsubscribe('mpv_av_uri', self.mpv_av_uri)
        cherrypy.engine.unsubscribe('ssdp_updateip', self.mpv_av_uri)
        cherrypy.engine.unsubscribe('app_notify', self.notification)

    def startCast(self):
        if self.running:
            return
        self.thread = threading.Thread(target=macast.run, args=())
        self.thread.start()
        self.running = True
        cherrypy.engine.subscribe('mpv_error', self.mpv_error)
        cherrypy.engine.subscribe('mpv_start', self.mpv_start)
        cherrypy.engine.subscribe('mpv_av_stop', self.mpv_av_stop)
        cherrypy.engine.subscribe('mpv_av_uri', self.mpv_av_uri)
        cherrypy.engine.subscribe('ssdp_updateip', self.ssdp_updateip)
        cherrypy.engine.subscribe('app_notify', self.notification)

    def mpv_start(self):
        logger.debug("mpv_start")

    def ssdp_updateip(self):
        logger.debug("ssdp_updateip")
        if self.ipItem is not None:
            self.ipItem.text = "IP: {}".format(Setting.getIP())

    def mpv_av_stop(self):
        logger.debug("mpv_av_stop")
        self.removeMenuItemByID(self.copyItem.id)
        self.copyItem = None

    def mpv_error(self):
        self.dialog(_("Cannot start player"))

    def mpv_av_uri(self, uri):
        logger.debug("mpv_av_uri: " + uri)
        self.copyItem = MenuItem(
            _("Copy Video URI"),
            key="c",
            callback=lambda _: pyperclip.copy(uri))
        self.appendMenuItemAfter(self.toggleItem.id, self.copyItem)

    def check(self, item):
        self.checkUpdate()

    def checkUpdate(self, verbose=True):
        try:
            res = requests.get(
                'https://api.github.com/repos/xfangfang/Macast/releases/latest'
            ).text
            res = json.loads(res)
            logger.debug("tag_name: {}".format(res['tag_name']))
            onlineVersion = re.findall(r'(\d+\.*\d+)', res['tag_name'])[0]
            if float(Setting.getVersion()) < float(onlineVersion):
                self.newUpdate(res['tag_name'])
            else:
                if verbose:
                    self.alert(_("You're up to date."))
        except Exception as e:
            logger.error("get update info error: {}".format(e))

    def autoCheckUpdate(self, item):
        item.checked = not item.checked
        Setting.set(SettingProperty.CheckUpdate,
                    1 if item.checked else 0)

    def startAtLogin(self, item):
        res = Setting.setStartAtLogin(not item.checked)
        if res[0] == 0:
            item.checked = not item.checked
            Setting.set(SettingProperty.StartAtLogin,
                        1 if item.checked else 0)
        else:
            self.notification(_("Error"), _(res[1]))

    def toggle(self, item):
        if self.running:
            self.stopCast()
            item.text = _('Start Cast')
        else:
            self.startCast()
            item.text = _('Stop Cast')

    def quit(self, item):
        if self.running:
            self.stopCast()
        super(Macast, self).quit(item)


if __name__ == '__main__':
    Macast().start()
