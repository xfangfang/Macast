# Copyright (c) 2021 by xfangfang. All Rights Reserved.

import os
import sys
import socket
import uuid
import json
import ctypes
import logging
import platform
import locale
import subprocess
from enum import Enum


logger = logging.getLogger("Utils")
logger.setLevel(logging.ERROR)

PORT = 6068
NAME = "Macast({})".format(platform.node())
SYSTEM = str(platform.system())
SYSTEM_VERSION = str(platform.release())

if sys.platform == 'darwin':
    from AppKit import NSPasteboard, NSArray, NSBundle
    SETTING_DIR = os.path.join(os.environ['HOME'], 'Library/Application Support/Macast')
else:
    SETTING_DIR = os.getcwd()

class SettingProperty(Enum):
    USN = 0
    PlayerHW = 1
    PlayerSize = 2
    PlayerPosition = 3
    CheckUpdate = 4
    StartAtLogin = 5

class Setting:
    setting = {}
    version = 'v0'
    setting_path = os.path.join(SETTING_DIR, "setting.json")
    last_ip = None
    mpv_path = 'mpv'

    @staticmethod
    def save():
        if not os.path.exists(SETTING_DIR):
            os.makedirs(SETTING_DIR)
        with open(Setting.setting_path, "w") as f:
            json.dump(obj = Setting.setting, fp = f)

    @staticmethod
    def load():
        logger.error("Load Setting")
        with open('.version', 'r') as f:
            Setting.version = f.read().strip()
        if not os.path.exists(Setting.setting_path):
            Setting.setting = {}
        else:
            with open(Setting.setting_path, "r") as f:
                Setting.setting = json.load(fp = f)
        return Setting.setting

    @staticmethod
    def getSystem():
        return str(platform.system())

    @staticmethod
    def getVersion():
        return Setting.version

    @staticmethod
    def getUSN():
        if 'USN' in Setting.setting: return Setting.setting['USN']
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
        lang = 'en_US'
        if sys.platform == 'darwin':
            lang = subprocess.check_output(["osascript", "-e", "user locale of (get system info)"]).decode().strip()
        elif sys.platform == 'win32':
            windll = ctypes.windll.kernel32
            lang = locale.windows_locale[windll.GetUserDefaultUILanguage()]
        else:
            lang = os.environ['LANG'].split('.')[0]
        return lang

    @staticmethod
    def setMpvPath(path):
        Setting.mpv_path = path

    @staticmethod
    def get(property, default = 1):
        if property.name in Setting.setting: return Setting.setting[property.name]
        Setting.setting[property.name] = default
        return default

    @staticmethod
    def set(property, data):
        Setting.setting[property.name] = data
        Setting.save()

    @staticmethod
    def setStartAtLogin(launch):
        if sys.platform == 'darwin':
            app_path = NSBundle.mainBundle().bundlePath()
            if not app_path.startswith("/Applications"):
                return (1, "You need move Macast.app to Applications folder.")
            app_name = app_path.split("/")[-1].split(".")[0]
            res = subprocess.getstatusoutput("""osascript -e 'tell application "System Events" to get the name of every login item'""")
            if res[0] == 1:
                return (1, "Cannot access System Events")
            apps = res[1].split(",")
            if launch:
                if app_name in apps:
                    return (0, "Macast is already in login items.")
                res = subprocess.getstatusoutput("""osascript -e 'tell application "System Events" to make login item at end with properties {{name: "{}",path:"{}", hidden:false}}'""".format(app_name, app_path))
            else:
                if app_name not in apps:
                    return (0, "Macast is already not in login items.")
                res = subprocess.getstatusoutput("""osascript -e 'tell application "System Events" to delete login item "{}"'""".format(app_name))
            print(res)
            return res[0]
    @staticmethod
    def copy2Pasteboard(uri):
        if sys.platform == 'darwin':
            pb = NSPasteboard.generalPasteboard()
            pb.clearContents()
            pb.writeObjects_(NSArray.arrayWithObject_(uri))

class XMLPath(Enum):
    BASE_PATH = os.path.abspath(os.path.dirname(__file__))
    DESCRIPTION = BASE_PATH + '/xml/Description.xml'
    ACTION_RESPONSE = BASE_PATH + '/xml/ActionResponse.xml'
    AV_TRANSPORT = BASE_PATH + '/xml/AVTransport.xml'
    CONNECTION_MANAGER = BASE_PATH + '/xml/ConnectionManager.xml'
    RENDERING_CONTROL = BASE_PATH + '/xml/RenderingControl.xml'
    EVENT_RESPONSE = BASE_PATH + '/xml/EventResponse.xml'

def loadXML(path):
    with open(path) as f:
        xml = f.read()
    return xml
