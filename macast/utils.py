# Copyright (c) 2021 by xfangfang. All Rights Reserved.

import os
import sys
import socket
import uuid
import json
import time
import ctypes
import appdirs
import logging
import platform
import locale
import cherrypy
import subprocess
from enum import Enum
import netifaces as ni
if sys.platform == 'darwin':
    from AppKit import NSBundle

logger = logging.getLogger("Utils")
DEFAULT_PORT = 1068
SETTING_DIR = appdirs.user_config_dir('Macast', 'xfangfang')


class SettingProperty(Enum):
    USN = 0
    CheckUpdate = 1
    StartAtLogin = 2
    MenubarIcon = 3
    ApplicationPort = 4
    DLNA_FriendlyName = 5
    DLNA_Renderer = 6


class Setting:
    setting = {}
    version = None
    setting_path = os.path.join(SETTING_DIR, "macast_setting.json")
    last_ip = None
    renderer_path = 'mpv'
    base_path = None
    friendly_name = "Macast({})".format(platform.node())

    @staticmethod
    def save():
        """Save user settings
        """
        if not os.path.exists(SETTING_DIR):
            os.makedirs(SETTING_DIR)
        with open(Setting.setting_path, "w") as f:
            json.dump(obj=Setting.setting, fp=f)

    @staticmethod
    def load():
        """Load user settings
        """
        logger.info("Load Setting")
        if Setting.version is None:
            try:
                with open(Setting.get_base_path('.version'), 'r') as f:
                    Setting.version = f.read().strip()
            except FileNotFoundError as e:
                Setting.version = "0.0"
        if bool(Setting.setting) is False:
            if not os.path.exists(Setting.setting_path):
                Setting.setting = {}
            else:
                with open(Setting.setting_path, "r") as f:
                    Setting.setting = json.load(fp=f)
        return Setting.setting

    @staticmethod
    def get_system_version():
        """Get system version
        """
        return str(platform.release())

    @staticmethod
    def get_system():
        """Get system name
        """
        return str(platform.system())

    @staticmethod
    def getVersion():
        """Get application version
        """
        return Setting.version

    @staticmethod
    def get_friendly_name():
        """Get application friendly name
        This name will show in the device search list of the DLNA client
        and as player window default name.
        """
        return Setting.get(SettingProperty.DLNA_FriendlyName,
                           Setting.friendly_name)

    @staticmethod
    def set_friendly_name(name):
        """Set application friendly name
        This name will show in the device search list of the DLNA client
        and as player window default name.
        """
        Setting.friendly_name = name

    @staticmethod
    def getUSN():
        """Get device Unique identification
        """
        if 'USN' in Setting.setting:
            return Setting.setting['USN']
        Setting.setting['USN'] = str(uuid.uuid4())
        Setting.save()
        return Setting.setting['USN']

    @staticmethod
    def is_ip_changed():
        return Setting.last_ip != Setting.get_ip()

    @staticmethod
    def get_ip():
        Setting.last_ip = []
        for i in ni.gateways()[ni.AF_INET]:
            for j in ni.ifaddresses(i[1])[ni.AF_INET]:
                Setting.last_ip.append((j['addr'], j['netmask']))
        return Setting.last_ip

    @staticmethod
    def get_port():
        """Get application port
        """
        return Setting.get(SettingProperty.ApplicationPort, DEFAULT_PORT)

    @staticmethod
    def get_locale():
        """Get the language settings of the system
        Default: en_US
        """
        if sys.platform == 'darwin':
            lang = subprocess.check_output(
                ["osascript", "-e",
                 "user locale of (get system info)"]).decode().strip()
        elif sys.platform == 'win32':
            windll = ctypes.windll.kernel32
            lang = locale.windows_locale[windll.GetUserDefaultUILanguage()]
        else:
            lang = os.environ.get('LANGUAGE')
            if lang is None:
                lang = os.environ['LANG']
            if lang is None:
                return 'en_US'
            lang = lang.split(':')[0].split('.')[0]
        return lang

    @staticmethod
    def set_renderer_path(path):
        """Set renderer path
        MacOS default: bin/MacOS/mpv
        Windows default: bin/mpv.exe
        Others Default: mpv
        """
        Setting.renderer_path = path

    @staticmethod
    def get(property, default=1):
        """Get application settings
        """
        if property.name in Setting.setting:
            return Setting.setting[property.name]
        Setting.setting[property.name] = default
        return default

    @staticmethod
    def set(property, data):
        """Set application settings
        """
        Setting.setting[property.name] = data
        Setting.save()

    @staticmethod
    def system_shell(shell):
        result = subprocess.run(shell, stdout=subprocess.PIPE)
        return result.returncode, result.stdout.decode('UTF-8').strip()

    @staticmethod
    def set_start_at_login(launch):
        if sys.platform == 'darwin':
            app_path = NSBundle.mainBundle().bundlePath()
            if not app_path.startswith("/Applications"):
                return (1, "You need move Macast.app to Applications folder.")
            app_name = app_path.split("/")[-1].split(".")[0]
            res = Setting.system_shell(
                ['osascript',
                 '-e',
                 'tell application "System Events" ' +
                 'to get the name of every login item'])
            if res[0] == 1:
                return (1, "Cannot access System Events.")
            apps = list(map(lambda app: app.strip(), res[1].split(",")))
            # apps which start at login
            if launch:
                if app_name in apps:
                    return (0, "Macast is already in login items.")
                res = Setting.system_shell(
                    ['osascript',
                     '-e',
                     'tell application "System Events" ' +
                     'to make login item at end with properties ' +
                     '{{name: "{}",path:"{}", hidden:false}}'.format(
                         app_name, app_path)
                     ])
            else:
                if app_name not in apps:
                    return (0, "Macast is already not in login items.")
                res = Setting.system_shell(
                    ['osascript',
                     '-e',
                     'tell application "System Events" ' +
                     'to delete login item "{}"'.format(app_name)])
            return res
        else:
            return (1, 'Not support current platform.')

    @staticmethod
    def get_base_path(path="."):
        """PyInstaller creates a temp folder and stores path in _MEIPASS
            https://stackoverflow.com/a/13790741
            see also: https://pyinstaller.readthedocs.io/en/stable/\
                runtime-information.html#run-time-information
        """
        if Setting.base_path is not None:
            return os.path.join(Setting.base_path, path)
        if getattr(sys, 'frozen', False) and hasattr(sys, '_MEIPASS'):
            Setting.base_path = sys._MEIPASS
        else:
            Setting.base_path = os.path.join(os.path.dirname(__file__), '.')
        return os.path.join(Setting.base_path, path)

    @staticmethod
    def get_server_info():
        return '{}/{} UPnP/1.0 Macast/{}'.format(Setting.get_system(),
                                                 Setting.get_system_version(),
                                                 Setting.getVersion())

    @staticmethod
    def get_system_env():
        # Get system env(for GNU/Linux and *BSD).
        # https://pyinstaller.readthedocs.io/en/stable/runtime-information.html#run-time-information
        env = dict(os.environ)
        logger.debug(env)
        lp_key = 'LD_LIBRARY_PATH'
        lp_orig = env.get(lp_key + '_ORIG')
        if lp_orig is not None:
            env[lp_key] = lp_orig
        else:
            env.pop(lp_key, None)
        return env

    @staticmethod
    def stop_service():
        """Stop all DLNA threads
        stop MPV
        stop DLNA HTTP Server
        stop SSDP
        stop SSDP notify thread
        """
        if cherrypy.engine.state in [cherrypy.engine.states.STOPPED,
                                     cherrypy.engine.states.STOPPING,
                                     cherrypy.engine.states.EXITING,
                                     ]:
            return
        while cherrypy.engine.state != cherrypy.engine.states.STARTED:
            time.sleep(0.5)
        cherrypy.engine.exit()

    @staticmethod
    def is_service_running():
        return cherrypy.engine.state in [cherrypy.engine.states.STARTING,
                                         cherrypy.engine.states.STARTED,
                                         ]


class XMLPath(Enum):
    BASE_PATH = os.path.dirname(__file__)
    DESCRIPTION = BASE_PATH + '/xml/Description.xml'
    AV_TRANSPORT = BASE_PATH + '/xml/AVTransport.xml'
    CONNECTION_MANAGER = BASE_PATH + '/xml/ConnectionManager.xml'
    RENDERING_CONTROL = BASE_PATH + '/xml/RenderingControl.xml'
    PROTOCOL_INFO = BASE_PATH + '/xml/SinkProtocolInfo.csv'


def loadXML(path):
    with open(path) as f:
        xml = f.read()
    return xml


def notify_error(msg=None):
    """publish a notification when error occured
    """
    def wrapper_fun(fun):
        def wrapper(*args, **kwargs):
            nonlocal msg
            try:
                return fun(*args, **kwargs)
            except Exception as e:
                logger.error(str(e))
                if msg is None:
                    msg = str(e)
                else:
                    logger.error(msg)
                cherrypy.engine.publish('app_notify', 'Error', msg)
        return wrapper
    return wrapper_fun
