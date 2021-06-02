# Copyright (c) 2021 by xfangfang. All Rights Reserved.

import os
import socket
import uuid
from enum import Enum

PORT = 6068
NAME = "Macast"
VERSION = "0.1"

class XMLPath(Enum):
    BASE_PATH = os.getcwd()
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

def getLocalIP():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('1.1.1.1', 80))
        ip = s.getsockname()[0]
    finally:
        s.close()
    return ip

LOCAL_IP = getLocalIP()
USN = uuid.uuid4()
