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

from macast_renderer.mpv import MPVRenderer
from macast import App, MenuItem, Setting, SettingProperty, Platform, Service

logger = logging.getLogger("Macast")
logger.setLevel(logging.DEBUG)

try:
    locale = Setting.get_locale()
    lang = gettext.translation(
        'macast', localedir=Setting.get_base_path('i18n'), languages=[locale])
    lang.install()
    logger.error("Macast Loading Language: {}".format(locale))
except Exception as e:
    _ = gettext.gettext
    logger.error("Macast Loading Default Language en_US")


class Macast(App):
    if sys.platform == 'linux':
        ICON_MAP = ['assets/icon.png',
                    'assets/menu_light_large.png',
                    'assets/menu_dark_large.png']
    else:
        ICON_MAP = ['assets/icon.png',
                    'assets/menu_light.png',
                    'assets/menu_dark.png']

    def __init__(self):
        # menu items
        self.toggle_menuitem = None
        self.setting_menuitem = None
        self.quit_menuitem = None
        self.ip_menuitem = None
        self.version_menuitem = None
        self.auto_check_update_menuitem = None
        self.start_at_login_menuitem = None
        self.menubar_icon_menuitem = None
        self.check_update_menuitem = None
        self.about_menuitem = None
        # dlna service thread
        self.thread = None
        # setting items
        self.setting_start_at_login = None
        self.setting_check = None
        self.setting_menubar_icon = None

        self.init_setting()
        self.renderer = MPVRenderer()
        self.dlna_service = Service(self.renderer)
        icon_path = Setting.get_base_path(Macast.ICON_MAP[self.setting_menubar_icon])
        template = None if self.setting_menubar_icon == 0 else True
        self.copy_menuitem = None
        super(Macast, self).__init__("Macast",
                                     icon_path,
                                     self.build_app_menu(),
                                     template
                                     )
        self.start_cast()
        logger.debug("Macast APP started")

    def build_app_menu(self):
        self.toggle_menuitem = MenuItem(_("Stop Cast"), self.on_toggle_service_click, key="p")
        self.setting_menuitem = MenuItem(_("Setting"), children=self.build_setting_menu())
        self.quit_menuitem = MenuItem(_("Quit"), self.quit, key="q")
        return [
            self.toggle_menuitem,
            None,
            self.setting_menuitem,
            self.quit_menuitem
        ]

    def build_setting_menu(self):
        self.ip_menuitem = MenuItem("{}:{}".format(
            Setting.get_ip(), Setting.get_port()), enabled=False)
        self.version_menuitem = MenuItem(
            "Macast (v{})".format(Setting.getVersion()), enabled=False)
        self.auto_check_update_menuitem = MenuItem(_("Auto Check Updates"),
                                                   self.on_auto_check_update_click,
                                                   checked=self.setting_check)
        self.start_at_login_menuitem = MenuItem(_("Start At Login"),
                                                self.on_start_at_login_click,
                                                checked=self.setting_start_at_login)
        platform_options = []
        if sys.platform == 'darwin':
            platform_options = [self.start_at_login_menuitem]
            # Reset StartAtLogin to prevent the user from turning off
            # this option from the system settings
            Setting.set_start_at_login(self.setting_start_at_login)
            self.menubar_icon_menuitem = MenuItem(_("Menubar Icon"),
                                                  children=App.build_menu_item_group([
                                                      _("AppIcon"),
                                                      _("Pattern"),
                                                  ], self.on_menubar_icon_change_click))
        else:
            self.menubar_icon_menuitem = MenuItem(_("Menubar Icon"),
                                                  children=App.build_menu_item_group([
                                                      _("AppIcon"),
                                                      _("PatternLight"),
                                                      _("PatternDark"),
                                                  ], self.on_menubar_icon_change_click))
        self.check_update_menuitem = MenuItem(_("Check For Updates"), self.on_check_click)
        self.about_menuitem = MenuItem(_("About"), self.on_about_click)

        self.menubar_icon_menuitem.items()[self.setting_menubar_icon].checked = True
        player_settings = self.renderer.renderer_setting.build_menu()
        if len(player_settings) > 0:
            player_settings.append(None)

        return [self.version_menuitem, self.ip_menuitem, None] + \
            player_settings + \
               [self.menubar_icon_menuitem, self.auto_check_update_menuitem] + \
            platform_options + \
               [None, self.check_update_menuitem, self.about_menuitem]

    def init_setting(self):
        Setting.load()
        self.setting_start_at_login = Setting.get(
            SettingProperty.StartAtLogin, 0)
        self.setting_check = Setting.get(
            SettingProperty.CheckUpdate, 1)
        self.setting_menubar_icon = Setting.get(
            SettingProperty.MenubarIcon, 1 if sys.platform == 'darwin' else 0)
        if self.setting_check:
            threading.Thread(target=self.check_update,
                             kwargs={
                                 'verbose': False
                             }).start()

    def init_platform_darwin(self):
        Setting.set_renderer_path(os.path.abspath('bin/MacOS/mpv'))

    def init_platform_win32(self):
        Setting.set_renderer_path(Setting.get_base_path('bin/mpv.exe'))

    def stop_cast(self):
        self.dlna_service.stop()
        self.thread.join()
        cherrypy.engine.unsubscribe('start', self.service_start)
        cherrypy.engine.unsubscribe('stop', self.service_stop)
        cherrypy.engine.unsubscribe('renderer_start', self.renderer_start)
        cherrypy.engine.unsubscribe('renderer_av_stop', self.renderer_av_stop)
        cherrypy.engine.unsubscribe('renderer_av_uri', self.renderer_av_uri)
        cherrypy.engine.unsubscribe('ssdp_update_ip', self.ssdp_update_ip)
        cherrypy.engine.unsubscribe('app_notify', self.notification)

    def start_cast(self):
        if Setting.is_service_running():
            return
        self.thread = threading.Thread(target=self.dlna_service.run)
        self.thread.start()
        cherrypy.engine.subscribe('start', self.service_start)
        cherrypy.engine.subscribe('stop', self.service_stop)
        cherrypy.engine.subscribe('renderer_start', self.renderer_start)
        cherrypy.engine.subscribe('renderer_av_stop', self.renderer_av_stop)
        cherrypy.engine.subscribe('renderer_av_uri', self.renderer_av_uri)
        cherrypy.engine.subscribe('ssdp_update_ip', self.ssdp_update_ip)
        cherrypy.engine.subscribe('app_notify', self.notification)

    def check_update(self, verbose=True):
        release_url = 'https://github.com/xfangfang/Macast/releases/latest'
        api_url = 'https://api.github.com/repos/xfangfang/Macast/releases/latest'
        try:
            res = json.loads(requests.get(api_url).text)
            online_version = re.findall(r'(\d+\.*\d+)', res['tag_name'])[0]

            logger.info("tag_name: {}".format(res['tag_name']))

            if float(Setting.getVersion()) < float(online_version):
                self.dialog(_("Macast New Update {}").format(res['tag_name']),
                            lambda _: self.open_browser(release_url),
                            ok="Update")
            else:
                if verbose:
                    self.alert(_("You're up to date."))
        except Exception as e:
            logger.error("get update info error: {}".format(e))

    # The followings are the callback function of program event

    def update_service_status(self):
        if Setting.is_service_running():
            self.toggle_menuitem.text = _('Stop Cast')
        else:
            self.toggle_menuitem.text = _('Start Cast')

    def service_start(self):
        """This function is called every time the DLNA service is started.
        Displays a notification reminding the user that the service has started
        """
        logger.info("service_start")
        if self.platform is Platform.Win32:
            msg = _("running at task bar")
        elif self.platform is Platform.Darwin:
            msg = _("running at menu bar")
        else:
            msg = _("running at desktop panel")
        self.notification(_("Macast is hidden"), msg, sound=False)
        self.update_service_status()

    def service_stop(self):
        """This function is called every time the DLNA service is stopped.
        """
        logger.info("service_stop")
        self.update_service_status()

    def ssdp_update_ip(self):
        """When the IP or port of the device changes,
        call this function to refresh the device address on the menu
        """
        logger.info("ssdp_update_ip")
        if self.ip_menuitem is not None:
            self.ip_menuitem.text = "{}:{}".format(Setting.get_ip(), Setting.get_port())

    def renderer_av_stop(self):
        logger.info("renderer_av_stop")
        self.remove_menu_item_by_id(self.copy_menuitem.id)
        self.copy_menuitem = None

    def renderer_start(self):
        pass

    def renderer_av_uri(self, uri):
        logger.info("renderer_av_uri: " + uri)
        self.copy_menuitem = MenuItem(
            _("Copy Video URI"),
            key="c",
            callback=lambda _: pyperclip.copy(uri))
        self.append_menu_item_after(self.toggle_menuitem.id, self.copy_menuitem)

    # The followings are the callback function of menu click

    def on_check_click(self, item):
        self.check_update()

    def on_auto_check_update_click(self, item):
        item.checked = not item.checked
        Setting.set(SettingProperty.CheckUpdate,
                    1 if item.checked else 0)

    def on_start_at_login_click(self, item):
        res = Setting.set_start_at_login(not item.checked)
        if res[0] == 0:
            item.checked = not item.checked
            Setting.set(SettingProperty.StartAtLogin,
                        1 if item.checked else 0)
        else:
            self.notification(_("Error"), _(res[1]))

    def on_about_click(self, _):
        self.open_browser('https://github.com/xfangfang/Macast')

    def on_toggle_service_click(self, item):
        if Setting.is_service_running():
            self.stop_cast()
        else:
            self.start_cast()

    def on_menubar_icon_change_click(self, item):
        for i in self.menubar_icon_menuitem.items():
            i.checked = False
        item.checked = True
        Setting.set(SettingProperty.MenubarIcon, item.data)
        icon_path = Setting.get_base_path(Macast.ICON_MAP[item.data])
        template = None if item.data == 0 else True
        self.update_icon(icon_path, template)

    def quit(self, item):
        if Setting.is_service_running():
            self.stop_cast()
        super(Macast, self).quit(item)


if __name__ == '__main__':
    Macast().start()
