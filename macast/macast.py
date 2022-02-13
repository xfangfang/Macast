# Copyright (c) 2021 by xfangfang. All Rights Reserved.

import os
import re
import sys
import time
import json
import cherrypy
import logging
import threading
import requests
import pyperclip
import gettext
import importlib

from .utils import SettingProperty, SETTING_DIR, notify_error, format_class_name
from .gui import App, MenuItem, Platform
from .protocol import DLNAProtocol
from .server import Service, SettingService
from .utils import RENDERER_DIR, PROTOCOL_DIR, TOOL_DIR, Setting, AssetsPath
from macast_renderer.mpv import MPVRenderer

logger = logging.getLogger("main")
_ = gettext.gettext


class MacastPlugin:

    def __init__(self, path, title="None", plugin_instance=None, platform='none'):
        # path is allowed to be set to None only when renderer is macast default plugin
        self.path = path
        self.title = title
        self.plugin_class = None
        self.plugin_instance = plugin_instance
        self.platform = platform
        if path:
            try:
                self.load_from_file(path)
            except Exception as e:
                cherrypy.engine.publish('app_notify', 'ERROR', 'Custom plugin load error.')
                logger.error(str(e))

    def get_info(self):
        props = ['menu', 'protocol', 'title', 'renderer', 'platform', 'version', 'author', 'desc']
        res = {'default': False}
        for i in props:
            res[i] = getattr(self, i, '')
        if getattr(self, 'renderer', None) is not None:
            res['type'] = 'renderer'
        elif getattr(self, 'protocol', None) is not None:
            res['type'] = 'protocol'
        elif getattr(self, 'tool', None) is not None:
            res['type'] = 'tool'
        if self.path is None:
            res['default'] = True
            res['desc'] = 'Macast default plugin'
            res['version'] = Setting.get_version_tag()
        return res

    def get_instance(self):
        if self.plugin_instance is None and self.plugin_class is not None:
            self.plugin_instance = self.plugin_class()

        return self.plugin_instance

    def check(self):
        """ Check if this renderer can run on your device
        """
        if self.plugin_class is None:
            return False
        if sys.platform in self.platform:
            return True

        logger.info(f"{self.title} support platform: {self.platform}")
        logger.info(f"{self.title} is not suit for this system.")
        return False

    def load_from_file(self, path):
        base_name = os.path.basename(path)[:-3]
        with open(path, 'r', encoding='utf-8') as f:
            renderer_file = f.read()
            metadata = re.findall("<macast.(.*?)>(.*?)</macast", renderer_file)
            logger.info("=" * 10 + f"< Load Plugin from {base_name}")
            for key, value in metadata:
                setattr(self, key, str(value))
        if hasattr(self, 'renderer'):
            module = importlib.import_module(f'{RENDERER_DIR}.{base_name}')
            logger.info('\n'.join([f'{k}: {v}' for k, v in metadata]) +
                        f'\nLoad plugin {self.renderer} done />\n'
                        )
            self.plugin_class = getattr(module, self.renderer, None)
        elif hasattr(self, 'protocol'):
            module = importlib.import_module(f'{PROTOCOL_DIR}.{base_name}')
            logger.info('\n'.join([f'{k}: {v}' for k, v in metadata]) +
                        f'\nLoad plugin {self.protocol} done />\n'
                        )
            self.plugin_class = getattr(module, self.protocol, None)
        elif hasattr(self, 'tool'):
            module = importlib.import_module(f'{TOOL_DIR}.{base_name}')
            logger.info('\n'.join([f'{k}: {v}' for k, v in metadata]) +
                        f'\nLoad plugin {self.tool} done />\n'
                        )
            self.plugin_class = getattr(module, self.tool, None)
        else:
            logger.error(f"Cannot find any plugin in {base_name}")
            return


class MacastPluginManager:

    def __init__(self, renderer_default, protocol_default):
        sys.path.append(SETTING_DIR)
        self.create_plugin_dir(RENDERER_DIR)
        self.create_plugin_dir(PROTOCOL_DIR)
        self.create_plugin_dir(TOOL_DIR)
        self.renderer_list = [renderer_default]
        self.renderer_list += self.load_macast_plugin(RENDERER_DIR)
        self.protocol_list = [protocol_default]
        self.protocol_list += self.load_macast_plugin(PROTOCOL_DIR)
        self.tool_list = self.load_macast_plugin(TOOL_DIR)

    def get_renderer(self, name):
        plugin = self.get_plugin_from_list(self.renderer_list, name)
        return plugin.get_instance()

    def get_protocol(self, name):
        plugin = self.get_plugin_from_list(self.protocol_list, name)
        return plugin.get_instance()

    def get_tool(self, name):
        plugin = self.get_plugin_from_list(self.tool_list, name)
        if plugin is None:
            return None
        return plugin.get_instance()

    def get_tools(self, names):
        tools = []
        for name in names:
            instance = self.get_tool(name)
            if instance is not None:
                tools.append(instance)
        return tools

    def get_info(self):
        res = []
        for r in self.renderer_list:
            res.append(r.get_info())
        for p in self.protocol_list:
            res.append(p.get_info())
        for p in self.tool_list:
            res.append(p.get_info())
        return res

    @staticmethod
    def get_plugin_from_list(plugin_list, title) -> MacastPlugin:
        for i in plugin_list:
            if title == i.title:
                logger.info(f"using plugin: {title}")
                return i
        else:
            if len(plugin_list) > 0:
                logger.info("using default plugin")
                return plugin_list[0]
        return None

    @staticmethod
    def load_macast_plugin(path: str):
        plugin_path = os.path.join(SETTING_DIR, path)
        if not os.path.exists(plugin_path):
            return
        plugin_list = []
        plugins = os.listdir(plugin_path)
        plugins = filter(lambda s: s.endswith('.py') and s != '__init__.py', plugins)
        for plugin in plugins:
            path = os.path.join(plugin_path, plugin)
            plugin_config = MacastPlugin(path)
            if plugin_config.check():
                plugin_list.append(plugin_config)
        return plugin_list

    @staticmethod
    @notify_error('Cannot create custom plugin dir.')
    def create_plugin_dir(path):
        custom_module_path = os.path.join(SETTING_DIR, path)
        if not os.path.exists(custom_module_path):
            os.makedirs(custom_module_path)
        init_file_path = os.path.join(custom_module_path, '__init__.py')
        if not os.path.exists(init_file_path):
            open(init_file_path, 'a').close()


class Macast(App):
    if sys.platform == 'win32':
        ICON_MAP = ['assets/icon.ico',
                    'assets/menu_light_large.png',
                    'assets/menu_dark_large.png']
    else:
        ICON_MAP = ['assets/icon.png',
                    'assets/menu_light.png',
                    'assets/menu_dark.png']

    def __init__(self, renderer, protocol, lang=gettext.gettext):
        global _
        _ = lang
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
        self.open_config_menuitem = None
        self.renderer_menuitem = None
        self.protocol_menuitem = None
        self.tool_menuitem = None
        self.advanced_menuitem = None
        self.copy_menuitem = None

        # setting items
        self.setting_start_at_login = None
        self.setting_check = None
        self.setting_menubar_icon = 0
        self.setting_renderer = ''
        self.setting_protocol = ''
        self.setting_tool = []
        self.init_setting()

        # load plugins from file
        self.plugin_manager = MacastPluginManager(
            MacastPlugin(None, format_class_name(renderer), renderer, 'darwin,win32,linux'),
            MacastPlugin(None, format_class_name(protocol), protocol, 'darwin,win32,linux'))
        cherrypy.engine.subscribe('get_plugin_info', self.plugin_manager.get_info)

        # init service
        self.service = Service(self.plugin_manager.get_renderer(self.setting_renderer),
                               self.plugin_manager.get_protocol(self.setting_protocol),
                               self.plugin_manager.get_tools(self.setting_tool))

        # init app
        icon_path = os.path.join(os.path.dirname(__file__), Macast.ICON_MAP[self.setting_menubar_icon])
        template = None if self.setting_menubar_icon == 0 else True
        super(Macast, self).__init__("Macast",
                                     icon_path,
                                     self.build_app_menu(),
                                     template
                                     )
        cherrypy.engine.subscribe('start', self.service_start)
        cherrypy.engine.subscribe('stop', self.service_stop)
        cherrypy.engine.subscribe('renderer_start', self.renderer_start)
        cherrypy.engine.subscribe('renderer_av_stop', self.renderer_av_stop)
        cherrypy.engine.subscribe('renderer_av_uri', self.renderer_av_uri)
        cherrypy.engine.subscribe('update_ip', self.update_service_ip)
        cherrypy.engine.subscribe('app_notify', self.notification)
        self.start_cast()
        logger.info("Macast APP started")

    def build_app_menu(self):
        self.toggle_menuitem = MenuItem(_("Stop Cast"), self.on_toggle_service_click, key="p")
        self.setting_menuitem = MenuItem(_("Setting"), children=self.build_setting_menu())
        self.advanced_menuitem = MenuItem(_("Advanced Setting"),
                                          lambda _: self.open_browser(
                                              'http://localhost:{}'.format(Setting.get_setting_port())),
                                          key="k")
        self.quit_menuitem = MenuItem(_("Quit"), self.quit, key="q")
        return [
            self.toggle_menuitem,
            None,
            self.setting_menuitem,
            self.advanced_menuitem,
            self.quit_menuitem
        ]

    def build_setting_menu(self):
        # common setting menu
        ip_text = "/".join([ip for ip, mask in Setting.get_ip()])
        port = Setting.get_port()
        self.ip_menuitem = MenuItem("{}:{}".format(ip_text, port), enabled=False)
        self.version_menuitem = MenuItem(
            "{} v{}".format(Setting.get_friendly_name(), Setting.get_version_tag()), enabled=False)
        self.auto_check_update_menuitem = MenuItem(_("Auto Check Updates"),
                                                   self.on_auto_check_update_click,
                                                   checked=self.setting_check)
        self.start_at_login_menuitem = MenuItem(_("Start At Login"),
                                                self.on_start_at_login_click,
                                                checked=self.setting_start_at_login)
        self.open_config_menuitem = MenuItem(_("Open Config Directory"), self.on_open_config_click)
        self.check_update_menuitem = MenuItem(_("Check For Updates"), self.on_check_click)
        self.about_menuitem = MenuItem(_("Help"),
                                       lambda _: self.open_browser(
                                           'http://localhost:{}?page=4'.format(Setting.get_setting_port())))

        # renderer select menu
        renderer_names = [r.title for r in self.plugin_manager.renderer_list]
        renderer_select = []
        if len(renderer_names) > 1:
            self.renderer_menuitem = self.build_menu_item_select(_("Renderers"),
                                                                 renderer_names,
                                                                 self.on_renderer_change_click,
                                                                 self.setting_renderer)
            renderer_select = [self.renderer_menuitem]

        # protocol select menu
        protocol_names = [r.title for r in self.plugin_manager.protocol_list]
        protocol_select = []
        if len(protocol_names) > 1:
            self.protocol_menuitem = self.build_menu_item_select(_("Protocols"),
                                                                 protocol_names,
                                                                 self.on_protocol_change_click,
                                                                 self.setting_protocol)
            protocol_select = [self.protocol_menuitem]

        # tool select menu
        tool_names = [r.title for r in self.plugin_manager.tool_list]
        tool_select = []
        if len(tool_names) > 0:
            self.tool_menuitem = self.build_menu_item_select(_("Tools"),
                                                             tool_names,
                                                             self.on_tool_select_click,
                                                             self.setting_tool)
            tool_select = [self.tool_menuitem]

        # renderer setting
        player_settings = self.service.renderer.renderer_setting.build_menu()
        if len(player_settings) > 0:
            player_settings.insert(0, MenuItem(_("Player Settings"), enabled=False), )
            player_settings.append(None)

        # protocol setting
        protocol_settings = self.service.protocol.protocol_setting.build_menu()
        if len(protocol_settings) > 0:
            protocol_settings.insert(0, MenuItem(_("Protocol Settings"), enabled=False))
            protocol_settings.append(None)

        # tool setting
        tool_settings = []
        tools = self.plugin_manager.get_tools(self.setting_tool)
        for t in tools:
            tool_sub_menu = t.build_menu()
            if len(tool_sub_menu) > 0:
                tool_settings.append(MenuItem(t.title, children=tool_sub_menu))
        if len(tool_settings) > 0:
            tool_settings.insert(0, MenuItem(_("Tools"), enabled=False))
            tool_settings.insert(0, None)

        # platform related setting
        platform_options = []
        # To judge whether Macast was launched by scripts or by packaged app.
        if sys.platform == 'darwin' and sys.executable.endswith("Contents/MacOS/python"):
            platform_options = [self.start_at_login_menuitem]
            # Reset StartAtLogin to prevent the user from turning off
            # this option from the system settings
            Setting.set_start_at_login(self.setting_start_at_login)
        elif sys.platform == 'win32' and "python" not in os.path.basename(sys.executable).lower():
            platform_options = [self.start_at_login_menuitem]
            Setting.set_start_at_login(self.setting_start_at_login)
        if sys.platform == 'darwin':
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
        self.menubar_icon_menuitem.items()[self.setting_menubar_icon].checked = True

        return [self.version_menuitem, self.ip_menuitem] + \
               renderer_select + \
               protocol_select + \
               tool_select + \
               tool_settings + \
               [None] + \
               player_settings + \
               protocol_settings + \
               [self.menubar_icon_menuitem,
                self.auto_check_update_menuitem,
                self.open_config_menuitem] + \
               platform_options + \
               [None, self.check_update_menuitem, self.about_menuitem]

    def init_setting(self):
        self.setting_start_at_login = Setting.get(SettingProperty.StartAtLogin, 0)
        self.setting_check = Setting.get(SettingProperty.CheckUpdate, 1)
        self.setting_menubar_icon = Setting.get(SettingProperty.MenubarIcon, 1 if sys.platform == 'darwin' else 0)
        self.setting_renderer = Setting.get(SettingProperty.Macast_Renderer, 'MPV')
        self.setting_protocol = Setting.get(SettingProperty.Macast_Protocol, 'DLNA')
        self.setting_tool = Setting.get(SettingProperty.Macast_Tool, [])
        if not isinstance(self.setting_tool, list):
            self.setting_tool = []
        if self.setting_check:
            threading.Thread(target=self.check_update,
                             kwargs={
                                 'verbose': False
                             },
                             daemon=True,
                             name="CHECKUPDATE_THREAD").start()

    def stop_cast(self):
        self.service.stop()

    def start_cast(self):
        self.service.run_async()

    def check_update(self, verbose=True):
        release_url = 'https://github.com/xfangfang/Macast/releases/latest'
        api_url = 'https://api.github.com/repos/xfangfang/Macast/releases/latest'
        try:
            res = json.loads(requests.get(api_url).text)
            online_version = re.findall(r'(\d+\.*\d+)', res['tag_name'])[0]

            logger.info("tag_name: {}".format(res['tag_name']))

            if float(Setting.get_version()) < float(online_version):
                self.dialog(_("Macast New Update {}").format(res['tag_name']),
                            lambda: self.open_browser(release_url),
                            ok="Update")
            else:
                if verbose:
                    self.notification("Macast", _("You're up to date."))
        except Exception as e:
            logger.error("get update info error: {}".format(e))
            self.notification('ERROR', str(e))

    # The followings are the callback function of program event

    def update_service_status(self):
        if Setting.is_service_running():
            self.toggle_menuitem.text = _('Stop Cast')
        else:
            self.toggle_menuitem.text = _('Start Cast')
        self.update_menu()

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
        if self.platform == Platform.Darwin:
            self.notification(_("Macast is hidden"), msg, sound=False)
        else:
            # Pystray may fail to send notifications due to incomplete initialization
            # during the startup, so wait a moment
            threading.Thread(target=lambda: (
                time.sleep(2),
                self.notification(_("Macast is hidden"), msg, sound=False),
            )).start()
        self.update_service_status()

    def service_stop(self):
        """This function is called every time the DLNA service is stopped.
        """
        logger.info("service_stop")
        self.update_service_status()

    def update_service_ip(self):
        """When the IP or port of the device changes,
        call this function to refresh the device address on the menu
        """
        logger.info(f"update_ip: {Setting.last_ip}")
        if self.ip_menuitem is not None:
            ip_text = "/".join([ip for ip, _ in Setting.get_ip()])
            port = Setting.get_port()
            self.ip_menuitem.text = "{}:{}".format(ip_text, port)
        self.version_menuitem.text = "{} v{}".format(Setting.get_friendly_name(), Setting.get_version_tag())
        self.update_menu()

    def renderer_av_stop(self):
        logger.info("renderer_av_stop")
        if self.copy_menuitem:
            self.remove_menu_item_by_id(self.copy_menuitem.id)
        self.copy_menuitem = None

    def renderer_start(self):
        pass

    def renderer_av_uri(self, uri):
        logger.info("renderer_av_uri: " + uri)
        if self.copy_menuitem is not None:
            self.copy_menuitem.callback = lambda _: pyperclip.copy(uri)
            return
        self.copy_menuitem = MenuItem(
            _("Copy Video URI"),
            key="c",
            callback=lambda _: pyperclip.copy(uri))
        self.append_menu_item_after(self.toggle_menuitem.id, self.copy_menuitem)

    # The followings are the callback function of menu click

    def on_protocol_change_click(self, item: MenuItem):
        protocol_config = self.plugin_manager.protocol_list[item.data]
        self.stop_cast()
        self.service.protocol = protocol_config.get_instance()
        Setting.set(SettingProperty.Macast_Protocol, protocol_config.title)
        self.setting_protocol = protocol_config.title
        self.setting_menuitem.children = self.build_setting_menu()
        # reload menu
        self.set_menu(self.menu)
        self.start_cast()
        cherrypy.engine.publish('app_notify', _('Info'), _('Change Protocol to {}').format(protocol_config.title))

    def on_renderer_change_click(self, item: MenuItem):
        renderer_config = self.plugin_manager.renderer_list[item.data]
        self.stop_cast()
        self.service.renderer = renderer_config.get_instance()
        Setting.set(SettingProperty.Macast_Renderer, renderer_config.title)
        self.setting_renderer = renderer_config.title
        self.setting_menuitem.children = self.build_setting_menu()
        # reload menu
        self.set_menu(self.menu)
        self.start_cast()
        cherrypy.engine.publish('app_notify', _('Info'), _('Change Renderer to {}').format(renderer_config.title))

    def on_tool_select_click(self, item: MenuItem):
        item.checked = not item.checked

        tool_config = self.plugin_manager.tool_list[item.data]
        if item.checked:
            self.setting_tool.append(tool_config.title)
            cherrypy.engine.publish('append_tool', tool_config.get_instance())
        else:
            self.setting_tool.remove(tool_config.title)
            cherrypy.engine.publish('remove_tool', tool_config.get_instance())
        Setting.set(SettingProperty.Macast_Tool, self.setting_tool)
        self.setting_menuitem.children = self.build_setting_menu()
        self.set_menu(self.menu)

    def on_open_config_click(self, item):
        self.open_directory(SETTING_DIR)

    def on_check_click(self, item):
        threading.Thread(target=self.check_update,
                         daemon=True,
                         name="CHECKUPDATE_M_THREAD").start()

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
            self.notification(_("Error"), res[1])

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
        icon_path = os.path.join(os.path.dirname(__file__), Macast.ICON_MAP[item.data])
        template = None if item.data == 0 else True
        self.update_icon(icon_path, template)

    def quit(self, item):
        if Setting.is_service_running():
            self.stop_cast()
        super(Macast, self).quit(item)


def get_lang():
    locale = Setting.get_locale()
    if not os.path.exists(os.path.join(AssetsPath.I18N, locale, 'LC_MESSAGES', 'macast.mo')):
        locale = locale.split("_")[0]
    logger.info("Macast Loading Language: {}".format(locale))
    try:
        lang = gettext.translation('macast', localedir=AssetsPath.I18N, languages=[locale])
        lang.install()
        return lang.gettext
    except:
        import builtins
        builtins.__dict__['_'] = gettext.gettext
        logger.error("Macast Loading Default Language en_US")
        return gettext.gettext


@notify_error("Unhandled error")
def gui(renderer=None, protocol=None):
    # setup logger
    Setting.setup_logger()

    # start setting http server
    SettingService().run()

    lang = get_lang()
    if renderer is None:
        renderer = MPVRenderer(lang, Setting.mpv_default_path)
    if protocol is None:
        protocol = DLNAProtocol()
    Macast(renderer, protocol, lang).start()


@notify_error("Unhandled error")
def cli(renderer=None, protocol=None):
    # setup logger
    Setting.setup_logger()

    # start setting http server
    SettingService().run()

    if renderer is None:
        renderer = MPVRenderer(path=Setting.mpv_default_path)
    if protocol is None:
        protocol = DLNAProtocol()
    Service(renderer, protocol).run()
