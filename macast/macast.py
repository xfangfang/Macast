# Copyright (c) 2021 by xfangfang. All Rights Reserved.

import os
import re
import sys
import time
import json
import cherrypy
import portend
import logging
import threading
import requests
import pyperclip
import gettext
import importlib
from cherrypy.process.plugins import Monitor
from cherrypy._cpserver import Server

from .utils import loadXML, XMLPath, Setting, SettingProperty, SETTING_DIR, notify_error
from .plugin import SSDPPlugin, RendererPlugin
from .renderer import Renderer
from .gui import App, MenuItem, Platform
from macast_renderer.mpv import MPVRenderer

logger = logging.getLogger("main")
logger.setLevel(logging.DEBUG)


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
        self.renderer_plugin.start()

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
        if port != Setting.get(SettingProperty.ApplicationPort, 0):
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


class RendererConfig:
    def __init__(self, path, title='Renderer', renderer_instance=None, platform='none'):
        # path is allowed to be set to None only when renderer is macast official renderer
        self.path = path
        self.title = "None"
        self.renderer = None
        self.renderer_instance = renderer_instance
        self.platform = platform
        self.title = title
        if path is not None:
            try:
                self.load_from_file(path)
            except Exception as e:
                cherrypy.engine.publish('app_notify', 'ERROR', 'Custom renderer load error.')
                logger.error(str(e))

    def get_instance(self):
        if self.renderer_instance is None and self.renderer is not None:
            self.renderer_instance = self.renderer()

        return self.renderer_instance

    def check(self):
        """ Check if this renderer can run on your device
        """
        if sys.platform in self.platform:
            if self.path is not None and os.path.exists(self.path) or self.path is None:
                return True

        logger.error("{} support platform: {}".format(self.title, self.platform))
        logger.error("{} is not suit for this system.".format(self.title))
        return False

    def load_from_file(self, path):
        base_name = os.path.basename(path).split('.')[0]
        with open(path, 'r', encoding='utf-8') as f:
            renderer_file = f.read()
            metadata = re.findall("<macast.(.*?)>(.*?)</macast", renderer_file)
            print("<Load Renderer from {}".format(base_name))
            for key, value in metadata:
                print('%-10s: %s' % (key, value))
                setattr(self, key, str(value))
            module = importlib.import_module('renderer.{}'.format(base_name))
            print('Load renderer {} done />'.format(self.renderer))
            self.renderer = getattr(module, self.renderer)

    @staticmethod
    @notify_error('Cannot create custom renderer dir.')
    def create_renderer_dir():
        sys.path.append(SETTING_DIR)
        custom_module_path = os.path.join(SETTING_DIR, 'renderer')
        if not os.path.exists(custom_module_path):
            os.makedirs(custom_module_path)
        init_file_path = os.path.join(custom_module_path, '__init__.py')
        if not os.path.exists(init_file_path):
            open(init_file_path, 'a').close()


class Macast(App):
    if sys.platform == 'linux':
        ICON_MAP = ['assets/icon.png',
                    'assets/menu_light_large.png',
                    'assets/menu_dark_large.png']
    else:
        ICON_MAP = ['assets/icon.png',
                    'assets/menu_light.png',
                    'assets/menu_dark.png']

    def __init__(self, renderer, lang=gettext.gettext):
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
        # dlna renderers
        RendererConfig.create_renderer_dir()
        self.renderer_list = [RendererConfig(None, 'Default', renderer, 'darwin,win32,linux')]
        self.load_custom_renderers()
        print('Load renderer MPVRenderer done')
        # dlna service thread
        self.thread = None
        # setting items
        self.setting_start_at_login = None
        self.setting_check = None
        self.setting_menubar_icon = None
        self.setting_dlna_renderer = None
        self.init_setting()
        self.dlna_service = Service(self.get_renderer_from_title(self.setting_dlna_renderer))
        icon_path = Setting.get_base_path(Macast.ICON_MAP[self.setting_menubar_icon])
        template = None if self.setting_menubar_icon == 0 else True
        self.copy_menuitem = None
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
        cherrypy.engine.subscribe('ssdp_update_ip', self.ssdp_update_ip)
        cherrypy.engine.subscribe('app_notify', self.notification)
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

    def load_custom_renderers(self):
        renderers_path = os.path.join(SETTING_DIR, 'renderer')
        if os.path.exists(renderers_path):
            renderers = os.listdir(renderers_path)
            renderers = filter(lambda s: s.endswith('.py') and s != '__init__.py', renderers)
            for renderer in renderers:
                path = os.path.join(renderers_path, renderer)
                renderer_config = RendererConfig(path)
                if renderer_config.check():
                    self.renderer_list.append(renderer_config)

    def build_setting_menu(self):
        ip_text = "/".join([ip for ip, _ in Setting.get_ip()])
        port = Setting.get_port()
        self.ip_menuitem = MenuItem("{}:{}".format(ip_text, port), enabled=False)
        self.version_menuitem = MenuItem(
            "Macast (v{})".format(Setting.getVersion()), enabled=False)
        self.auto_check_update_menuitem = MenuItem(_("Auto Check Updates"),
                                                   self.on_auto_check_update_click,
                                                   checked=self.setting_check)
        self.start_at_login_menuitem = MenuItem(_("Start At Login"),
                                                self.on_start_at_login_click,
                                                checked=self.setting_start_at_login)

        renderer_names = [r.title for r in self.renderer_list]
        renderer_select = []
        if len(renderer_names) > 1:
            self.renderer_menuitem = MenuItem(_("Renderers"),
                                              children=App.build_menu_item_group(renderer_names,
                                                                                 self.on_renderer_change_click))
            renderer_select = [self.renderer_menuitem]
            for i in self.renderer_menuitem.children:
                if i.text == self.setting_dlna_renderer:
                    i.checked = True
                    break
            else:
                self.renderer_menuitem.children[0].checked = True

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
        self.open_config_menuitem = MenuItem(_("Open Config Directory"), self.on_open_config_click)
        self.check_update_menuitem = MenuItem(_("Check For Updates"), self.on_check_click)
        self.about_menuitem = MenuItem(_("About"), self.on_about_click)

        self.menubar_icon_menuitem.items()[self.setting_menubar_icon].checked = True
        player_settings = self.dlna_service.renderer.renderer_setting.build_menu()
        if len(player_settings) > 0:
            player_settings.append(None)

        return [self.version_menuitem, self.ip_menuitem] + renderer_select + [None] + \
            player_settings + \
               [self.menubar_icon_menuitem, self.auto_check_update_menuitem] + \
            platform_options + \
               [None, self.open_config_menuitem, self.check_update_menuitem, self.about_menuitem]

    def init_setting(self):
        Setting.load()
        self.setting_start_at_login = Setting.get(SettingProperty.StartAtLogin, 0)
        self.setting_check = Setting.get(SettingProperty.CheckUpdate, 1)
        self.setting_menubar_icon = Setting.get(SettingProperty.MenubarIcon, 1 if sys.platform == 'darwin' else 0)
        self.setting_dlna_renderer = Setting.get(SettingProperty.DLNA_Renderer, 'Default')
        if self.setting_check:
            threading.Thread(target=self.check_update,
                             kwargs={
                                 'verbose': False
                             },
                             daemon=True,
                             name="CHECKUPDATE_THREAD").start()

    def get_renderer_from_title(self, title):
        for i in self.renderer_list:
            if title == i.title:
                print("using renderer: {}".format(title))
                return i.get_instance()
        else:
            print("using default renderer")
            Setting.set(SettingProperty.DLNA_Renderer, 'Default')
            return self.renderer_list[0].get_instance()

    def stop_cast(self):
        self.dlna_service.stop()
        self.thread.join()

    def start_cast(self):
        if Setting.is_service_running():
            return
        self.thread = threading.Thread(target=self.dlna_service.run, name="DLNA_SERVICE_THREAD")
        self.thread.start()

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
                    self.notification("Macast", _("You're up to date."))
        except Exception as e:
            logger.error("get update info error: {}".format(e))

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
                time.sleep(1),
                self.notification(_("Macast is hidden"), msg, sound=False),
            )).start()
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
            ip_text = "/".join([ip for ip, _ in Setting.get_ip()])
            port = Setting.get_port()
            self.ip_menuitem.text = "{}:{}".format(ip_text, port)
        self.update_menu()

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

    def on_renderer_change_click(self, item):
        renderer_config = self.renderer_list[item.data]
        self.dlna_service.renderer = renderer_config.get_instance()
        Setting.set(SettingProperty.DLNA_Renderer, renderer_config.title)
        self.setting_dlna_renderer = renderer_config.title
        self.setting_menuitem.children = self.build_setting_menu()
        # reload menu
        self.set_menu(self.menu)
        cherrypy.engine.publish('app_notify', _('Info'), _('Change Renderer to {}.').format(renderer_config.title))

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


def gui(renderer=None, lang=gettext.gettext):
    if renderer is None:
        renderer = MPVRenderer(lang)
    Macast(renderer, lang).start()


def cli(renderer=None):
    if renderer is None:
        renderer = MPVRenderer()
    Service(renderer).run()
