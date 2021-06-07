# Copyright (c) 2021 by xfangfang. All Rights Reserved.

import os
import socket
import uuid
import json
import logging
import platform
from enum import Enum

logger = logging.getLogger("Utils")
logger.setLevel(logging.ERROR)

PORT = 6068
NAME = "Macast({})".format(platform.node())
SYSTEM = str(platform.system())
SYSTEM_VERSION = str(platform.release())
HOME_PATH = os.environ['HOME']
SETTING_DIR = os.path.join(HOME_PATH, 'Library/Application Support/Macast')

class Setting:
    setting = {}
    version = 'v0'
    setting_path = os.path.join(SETTING_DIR, "setting.json")
    last_ip = None

    @staticmethod
    def save():
        if not os.path.exists(SETTING_DIR):
            os.makedirs(SETTING_DIR)
        with open(Setting.setting_path, "w") as f:
            json.dump(obj = Setting.setting, fp = f)

    @staticmethod
    def load():
        logger.error("Load Setting")
        if not os.path.exists(Setting.setting_path):
            Setting.setting = {}
        with open(Setting.setting_path, "r") as f:
            Setting.setting = json.load(fp=f)
        with open('.version', 'r') as f:
            Setting.version = f.read().strip()

    @staticmethod
    def getVersion():
        return Setting.version

    @staticmethod
    def getUSN():
        if 'USN' in Setting.setting: return Setting.setting['USN']
        logger.error(Setting.setting)
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

class XMLPath(Enum):
    BASE_PATH = os.getcwd() #os.path.abspath(os.path.dirname(__file__))
    DESCRIPTION = BASE_PATH + '/xml/description.xml'
    ACTION_RESPONSE = BASE_PATH + '/xml/ActionResponse.xml'
    AV_TRANSPORT = BASE_PATH + '/xml/AVTransport.xml'
    CONNECTION_MANAGER = BASE_PATH + '/xml/ConnectionManager.xml'
    RENDERING_CONTROL = BASE_PATH + '/xml/RenderingControl.xml'
    EVENT_RESPONSE = BASE_PATH + '/xml/EventResponse.xml'

def loadXML(path):
    with open(path) as f:
        xml = f.read()
    return xml
