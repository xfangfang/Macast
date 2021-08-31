# Copyright (c) 2021 by xfangfang. All Rights Reserved.

import os
import sys
import socket
import uuid
import json
import ctypes
import appdirs
import logging
import platform
import locale
import subprocess
from enum import Enum
if sys.platform == 'darwin':
    from AppKit import NSBundle

logger = logging.getLogger("Utils")
PORT = 1068

SETTING_DIR = appdirs.user_config_dir('Macast', 'xfangfang')


class SettingProperty(Enum):
    USN = 0
    PlayerHW = 1
    PlayerSize = 2
    PlayerPosition = 3
    CheckUpdate = 4
    StartAtLogin = 5
    MenubarIcon = 6


class Setting:
    setting = {}
    version = 'v0'
    setting_path = os.path.join(SETTING_DIR, "macast_setting.json")
    last_ip = None
    mpv_path = 'mpv'
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
        with open(Setting.getPath('.version'), 'r') as f:
            Setting.version = f.read().strip()
        if not os.path.exists(Setting.setting_path):
            Setting.setting = {}
        else:
            with open(Setting.setting_path, "r") as f:
                Setting.setting = json.load(fp=f)
        return Setting.setting

    @staticmethod
    def getSystemVersion():
        """Get system version
        """
        return str(platform.release())

    @staticmethod
    def getSystem():
        """Get system name
        """
        return str(platform.system())

    @staticmethod
    def getVersion():
        """Get application version
        """
        return Setting.version

    @staticmethod
    def getFriendlyName():
        """Get application friendly name
        This name will show in the device search list of the DLNA client
        and as player window default name.
        """
        return Setting.friendly_name

    @staticmethod
    def setFriendlyName(name):
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
    def isIPChanged():
        return Setting.last_ip != Setting.getIP()

    @staticmethod
    def getIP():
        ip = None
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(('1.1.1.1', 80))
            ip = s.getsockname()[0]
        except Exception as e:
            logger.error("Cannot get ip")
        finally:
            s.close()
        Setting.last_ip = ip
        return ip

    @staticmethod
    def getLocale():
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
    def setMpvPath(path):
        """Set mpv path
        MacOS default: bin/MacOS/mpv
        Windows default: bin/mpv.exe
        Others Default: mpv
        """
        Setting.mpv_path = path

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
    def systemShell(shell):
        result = subprocess.run(shell, stdout=subprocess.PIPE)
        return (result.returncode, result.stdout.decode('UTF-8').strip())

    @staticmethod
    def setStartAtLogin(launch):
        if sys.platform == 'darwin':
            app_path = NSBundle.mainBundle().bundlePath()
            if not app_path.startswith("/Applications"):
                return (1, "You need move Macast.app to Applications folder.")
            app_name = app_path.split("/")[-1].split(".")[0]
            res = Setting.systemShell(
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
                res = Setting.systemShell(
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
                res = Setting.systemShell(
                    ['osascript',
                     '-e',
                     'tell application "System Events" ' +
                     'to delete login item "{}"'.format(app_name)])
            return res
        else:
            return (1, 'Not support current platform.')

    @staticmethod
    def getPath(path="."):
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
            Setting.base_path = os.getcwd()
        return os.path.join(Setting.base_path, path)

    @staticmethod
    def getServerInfo():
        return '{}/{} UPnP/1.0 Macast/{}'.format(Setting.getSystem(),
                                                 Setting.getSystemVersion(),
                                                 Setting.getVersion())

    @staticmethod
    def getSystemEnv():
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


class XMLPath(Enum):
    BASE_PATH = Setting.getPath(os.path.dirname(__file__))
    DESCRIPTION = BASE_PATH + '/xml/Description.xml'
    AV_TRANSPORT = BASE_PATH + '/xml/AVTransport.xml'
    CONNECTION_MANAGER = BASE_PATH + '/xml/ConnectionManager.xml'
    RENDERING_CONTROL = BASE_PATH + '/xml/RenderingControl.xml'
    PROTOCOL_INFO = BASE_PATH + '/xml/SinkProtocolInfo.csv'


def loadXML(path):
    with open(path) as f:
        xml = f.read()
    return xml
