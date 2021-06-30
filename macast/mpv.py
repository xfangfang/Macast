# Copyright (c) 2021 by xfangfang. All Rights Reserved.

import re
import os
import json
import time
import socket
import uuid
import http.client
import subprocess
import logging
import threading
import copy
import cherrypy
from enum import Enum
from lxml import etree as ET

if os.name == 'nt':
    import _winapi
    from multiprocessing.connection import PipeConnection

from .utils import loadXML, XMLPath, NAME, Setting, SYSTEM, SYSTEM_VERSION, SettingProperty


logger = logging.getLogger("Render")
logger.setLevel(logging.INFO)

class ObserveProperty(Enum):
    volume = 1
    time_pos = 2
    pause = 3
    mute = 4
    duration = 5

class ObserveClient():
    def __init__(self, url, timeout = 1800):
        self.url = url
        self.startTime = int(time.time())
        self.sid = "uuid:{}".format(uuid.uuid4())
        self.timeout = timeout
        self.seq = 0
        self.host = re.findall("//([0-9:\.]*)", url)[0]
        self.path = re.findall("//[0-9:\.]*(.*)$", url)[0]
        self.error = 0


    def isTimeout(self):
        return int(time.time()) - self.startTime > self.timeout

    def update(self):
        self.startTime = int(time.time())

class DataType(Enum):
    boolean = 'boolean'
    i2 = 'i2'
    ui2 = 'ui2'
    i4 = 'i4'
    ui4 = 'ui4'
    string = 'string'

class StateVariable:
    def __init__(self, name, sendEvents, datatype):
        self.name = name
        self.sendEvents = True if sendEvents == 'yes' else False
        self.datatype = DataType(datatype)
        self.minimum = None
        self.maximum = None
        self.allowedValueList = None
        self.value = '' if self.datatype == DataType.string else 0

    def setAllowedValueList(self, values):
        self.allowedValueList = values

    def setAllowedValueRange(self, minimum, maximum):
        self.minimum = minimum
        self.maximum = maximum

class Argument:
    def __init__(self, name, state, value = None):
        self.name = name
        self.state = state
        self.value = value

class Action:
    def __init__(self, name, input, output):
        self.name = name
        self.input = input
        self.output = output

class Render():
    def __init__(self):
        self.av_transport = ET.parse(XMLPath.AV_TRANSPORT.value).getroot()
        self.rendering_control = ET.parse(XMLPath.RENDERING_CONTROL.value).getroot()
        self.conection_manager = ET.parse(XMLPath.CONNECTION_MANAGER.value).getroot()
        self.action_response = ET.parse(XMLPath.ACTION_RESPONSE.value).getroot()
        self.event_response = ET.parse(XMLPath.EVENT_RESPONSE.value).getroot()
        self.running = False
        self.stateList = {}
        self.actionList = {}
        self.stateChangeList = {}
        self.stateChangeEvent = threading.Event()
        self.stateChangeEvent.set()
        self.stateSetEvent = threading.Event()
        self.stateSetEvent.clear()
        self.eventThread = None
        self.eventSubcribes = {}
        self._buildAction('AVTransport', self.av_transport)
        self._buildAction('RenderingControl', self.rendering_control)
        self._buildAction('ConnectionManager', self.conection_manager)
        # set default value
        self.setState('TransportPlaySpeed', 1)
        self.setState('TransportStatus', 'OK')
        self.setState('RelativeCounterPosition', 2147483647)
        self.setState('AbsoluteCounterPosition', 2147483647)

    def addSubcribe(self, url):
        logger.error("APPEND SUBSCRIBE: " + url)
        client = ObserveClient(url)
        self.eventSubcribes[client.sid] = client
        return {
            "SID": client.sid,
            "TIMEOUT": "Second-{}".format(client.timeout)
        }

    def removeSubcribe(self, sid):
        if sid in self.eventSubcribes:
            del self.eventSubcribes[sid]
            return 200
        return 412

    def renewSubcribe(self, sid):
        if sid in self.eventSubcribes:
            self.eventSubcribes.update()
            return 200
        return 412

    def sendEventCallback(self, host, path, headers, data):
        root = copy.deepcopy(self.event_response)
        for i in data:
            p = ET.SubElement(root[0][0][0][0], i)
            p.set('val', str(data[i].value))
        data = ET.tostring(root, encoding="UTF-8", xml_declaration=True)

        # logger.debug("EVENT DATA: "+data.decode())
        conn = http.client.HTTPConnection(host, timeout = 1)
        conn.request("NOTIFY", path, data, headers)
        conn.close()

    def eventCallback(self, stateChangeList):
        logger.debug("state change callback " + str(stateChangeList))
        if not bool(stateChangeList): return
        removeList = []
        for sid in self.eventSubcribes:
            client = self.eventSubcribes[sid]
            if client.isTimeout():
                removeList.append(client.sid)
                continue
            try:
                self.sendEventCallback(
                    client.host,
                    client.path,
                    {
                        "NT": "upnp:event",
                        "NTS": "upnp:propchange",
                        "Content-Type": 'text/xml; charset="utf-8"',
                        "SERVER": "{}/{} UPnP/1.0 Macast/{}".format(SYSTEM, SYSTEM_VERSION, Setting.getVersion()),
                        "SID": client.sid,
                        "SEQ": client.seq,
                        "TIMEOUT": "Second-{}".format(client.timeout)
                    },
                    stateChangeList
                )
                client.seq = client.seq + 1
            except Exception as e:
                logger.error("send event error: "+str(e))
                client.error = client.error + 1
                if client.error > 10:
                    logger.debug("remove "+ client.sid)
                    removeList.append(client.sid)
        for sid in removeList:
            self.removeSubcribe(sid)

    def start(self):
        if not self.running:
            self.running = True
            self.eventThread = threading.Thread(target=self.event, daemon=True)
            self.eventThread.start()
        else:
            return

    def stop(self):
        self.running = False
        self.stateChangeEvent.set()
        self.stateSetEvent.set()

    def event(self):
        interval = 1
        while self.running:
            self.stateSetEvent.wait()
            time.sleep(interval)
            if not self.running: return
            if bool(self.eventSubcribes):
                self.stateChangeEvent.clear()
                time.sleep(0.05)
                self.eventCallback(self.stateChangeList)
                self.stateChangeList = {}
                self.stateSetEvent.clear()
                self.stateChangeEvent.set()

    def call(self, rawbody):
        root = ET.fromstring(rawbody)[0][0]
        param = {}
        for node in root: param[node.tag] = node.text
        logger.debug(param)
        action = root.tag.split('}')[1]
        service = root.tag.split(":")[3]
        method = "{}_{}".format(service, action)
        if method not in ['AVTransport_GetPositionInfo', 'AVTransport_GetTransportInfo', 'RenderingControl_GetVolume']:
            logger.info(method)
        res = {}
        if hasattr(self, method):
            data = {}
            input = self.actionList[service][action].input
            for arg in input:
                data[arg.name] = Argument(
                    arg.name,
                    arg.state,
                    param[arg.name] if arg.name in param else None
                )
                if arg.name in param: self.setState(arg.state, param[arg.name])
            res = getattr(self, method)(data)
        else:
            output = self.actionList[service][action].output
            for arg in output:
                res[arg.name] = self.stateList[arg.state].value

        # build response xml
        root = copy.deepcopy(self.action_response)
        ns = 'urn:schemas-upnp-org:service:{}:1'.format(service)
        response = ET.SubElement(root[0], '{{{}}}{}Response'.format(ns, action))
        for key in res:
            prop = ET.SubElement(response, key)
            prop.text = str(res[key])
        return ET.tostring(root, encoding="UTF-8", xml_declaration=True)

    def setState(self, name, value):
        self.stateChangeEvent.wait()
        self.stateList[name].value = value
        self.stateChangeList[name] = self.stateList[name]
        if name == 'AVTransportURI' and 'TransportState' in self.stateChangeList:
            # remove TransportState(stopped) if set new uri
            if self.stateChangeList['TransportState'] == 'STOPPED':
                del self.stateChangeList['TransportState']
        self.stateSetEvent.set()

    def getState(self, name):
        return self.stateList[name].value

    def _buildAction(self, service, xml):

        ns = '{urn:schemas-upnp-org:service-1-0}'
        # add var
        for stateVariable in xml.iter(ns + 'stateVariable'):
            name = stateVariable.find(ns + "name").text
            data = StateVariable(
                name,
                stateVariable.attrib['sendEvents'],
                stateVariable.find(ns + "dataType").text
            )
            allowedValueList = stateVariable.find(ns + "allowedValueList")
            if allowedValueList is not None:
                values = [value.text for value in allowedValueList.findall(ns + "allowedValue")]
                data.setAllowedValueList(values)

            allowedValueRange = stateVariable.find(ns + "allowedValueRange")
            if allowedValueRange is not None:
                data.setAllowedValueRange(
                    int(allowedValueRange.find(ns + "minimum").text),
                    int(allowedValueRange.find(ns + "maximum").text)
                )
            self.stateList[name] = data

        # add action
        actions = {}
        for action in xml.iter(ns + 'action'):
            name = action.find(ns + "name").text
            input = []
            output = []
            argumentList = action.find(ns + "argumentList")
            if argumentList is not None:
                l = argumentList.findall(ns + 'argument')
                for argument in l:
                    data = Argument(
                        argument.find(ns + "name").text,
                        argument.find(ns + "relatedStateVariable").text
                    )
                    if argument.find(ns + "direction").text == 'in':
                        input.append(data)
                    else:
                        output.append(data)
            actions[name] = Action(name, input, output)
        self.actionList[service] = actions


class MPVRender(Render):
    """
    When the DLNA client accesses, MPVRender will returns the state value
        corresponding to "out" section in the action specified in the service XML file by default.
    When some "service_action" methods are implemented (such as "RenderingControl_SetVolume"),
        the DLNA client's access will be automatically directed to these methods
    """

    def __init__(self):
        super(MPVRender, self).__init__()
        if os.name == 'nt':
            self.mpv_sock = os.path.abspath(r"\\.\pipe\macast_mpvsocket")
        else:
            self.mpv_sock = '/tmp/macast_mpvsocket'
        self.proc = None
        self.mpvThread = None
        self.ipcThread = None
        self.ipcSock = None
        self.pause = False # changed with pause action
        self.playing = False # changed with start and stop
        self.willStop = False # if this is True that mpv will stop after 0.2s
        self.ipc_running = False

    def RenderingControl_SetVolume(self, data):
        volume = data['DesiredVolume']
        self.sendCommand(['set_property', 'volume', volume.value])
        return {}

    def RenderingControl_SetMute(self, data):
        logger.debug(data)

        mute = data['DesiredMute']
        logger.debug(mute.value)
        if mute.value == 0 or mute.value == '0':
            mute = False
        else:
            mute = True
        self.sendCommand(['set_property', 'mute', "yes" if mute else "no"])
        return {}

    def AVTransport_SetAVTransportURI(self, data):
        # some client send "stop action" before SetAVTransportURI(nearly the same time)
        # sleep 0.1s to reduce the closing times of MPV
        time.sleep(0.1)

        uri = data['CurrentURI'].value
        cherrypy.engine.publish('mpv_av_uri', uri)
        self.setState('AVTransportURI', uri)
        self.sendCommand(['loadfile', uri, 'replace'])
        meta = data['CurrentURIMetaData'].value
        self.setState('AVTransportURIMetaData', meta)
        logger.error(uri)
        title = NAME
        if meta:
            title = re.findall("title>(.*?)</",meta)
            if len(title) > 0: title = title[0]
        self.sendCommand(['set_property', 'title', title])
        self.sendCommand(['set_property', 'pause', False])
        self.setState('RelativeTimePosition', '00:00:00')
        self.setState('AbsoluteTimePosition', '00:00:00')
        self.willStop = False
        return {}

    def AVTransport_Play(self, data):
        self.sendCommand(['set_property', 'pause', False])
        self.setState('TransportState', 'PLAYING')
        return {}

    def AVTransport_Pause(self, data):
        self.sendCommand(['set_property', 'pause', True])
        self.setState('TransportState', 'PAUSED_PLAYBACK')
        return {}

    def AVTransport_Seek(self, data):
        logger.error("SEEK-----------------------")
        target = data['Target']
        self.sendCommand(['seek', target.value, 'absolute'])
        self.setState('RelativeTimePosition', target.value)
        self.setState('AbsoluteTimePosition', target.value)
        return {}

    def AVTransport_Stop(self, data):
        # some client send "stop action" before SetAVTransportURI(nearly the same time)
        # sleep 0.2s to reduce the closing times of MPV
        self.willStop = True
        logger.debug("AVTransport_Stop1 "+str(self.willStop))
        time.sleep(0.2)
        if self.willStop:
            self.sendCommand(['stop'])
            self.setState('TransportState', 'STOPPED')
        logger.debug("AVTransport_Stop2 "+str(self.willStop))
        return {}

    # set several property that needed observe
    def setObserve(self):
        self.sendCommand(['observe_property', ObserveProperty.volume.value, 'volume'])
        self.sendCommand(['observe_property', ObserveProperty.time_pos.value, 'time-pos'])
        self.sendCommand(['observe_property', ObserveProperty.pause.value, 'pause'])
        self.sendCommand(['observe_property', ObserveProperty.mute.value, 'mute'])
        self.sendCommand(['observe_property', ObserveProperty.duration.value, 'duration'])

    # update player state from mpv
    def updateState(self, res):
        res = json.loads(res)
        if 'id' in res:
            if res['id'] == ObserveProperty.volume.value:
                logger.info(res)
                if 'data' in res:
                    self.setState('Volume', int(res['data']))
            elif res['id'] == ObserveProperty.time_pos.value:
                if 'data' not in res:
                    time = '00:00:00'
                else:
                    sec = int(res['data'])
                    time = '%d:%02d:%02d' % (sec // 3600, (sec % 3600) // 60, sec % 60)
                self.setState('RelativeTimePosition', time)
                self.setState('AbsoluteTimePosition', time)
            elif res['id'] == ObserveProperty.pause.value:
                logger.info(res)
                if self.playing is False: return
                if res['data']:
                    self.pause = True
                    state = "PAUSED_PLAYBACK"
                else:
                    self.pause = False
                    state = "PLAYING"
                self.setState('TransportState', state)
            elif res['id'] == ObserveProperty.mute.value:
                self.setState('Mute', res['data'])
            elif res['id'] == ObserveProperty.duration.value:
                if 'data' not in res:
                    time = '00:00:00'
                else:
                    sec = int(res['data'])
                    time = '%d:%02d:%02d' % (sec // 3600, (sec % 3600) // 60, sec % 60)
                    cherrypy.engine.publish('mpv_update_duration', time)
                    logger.info("update duration "+time)
                self.setState('CurrentTrackDuration', time)
                self.setState('CurrentMediaDuration', time)
            elif res['id'] == ObserveProperty.idle.value:
                logger.info(res)
        elif 'event' in res:
            logger.info(res)
            if res['event'] == 'end-file':
                cherrypy.engine.publish('mpv_av_stop')
                self.playing = False
                if res['reason'] == 'error':
                    self.setState('TransportStatus', 'ERROR_OCCURRED')
                elif res['reason'] == 'eof':
                    self.setState('TransportState', 'NO_MEDIA_PRESENT')
                else:
                    self.setState('TransportState', 'STOPPED')
            elif res['event'] == 'start-file':
                self.playing = True
                self.setState('TransportState', 'TRANSITIONING')
                self.setState('TransportStatus', 'OK')
            elif res['event'] == 'seek':
                self.setState('TransportState', 'TRANSITIONING')
                self.setState('TransportStatus', 'OK')
            elif res['event'] == 'idle':
                # video comes to end
                self.playing = False
                self.setState('TransportState', 'STOPPED')
                self.setState('TransportStatus', 'OK')
            elif res['event'] == 'playback-restart':
                # video is ready to play
                if self.pause:
                    self.setState('TransportState', 'PAUSED_PLAYBACK')
                    self.setState('TransportStatus', 'OK')
                else:
                    self.setState('TransportState', 'PLAYING')
                    self.setState('TransportStatus', 'OK')

        else:
            logger.debug(res)

    # send command to mpv
    def sendCommand(self, command):
        logger.debug("send command: "+str(command))
        data = {"command" :command}
        msg = json.dumps(data) + '\n'
        try:
            if os.name == 'nt':
                self.ipcSock.send_bytes(msg.encode())
            else:
                self.ipcSock.sendall(msg.encode())
            return True
        except Exception as e:
            logger.error('sendCommand: '+str(e))
            return False

    # start ipc thread (communicate with mpv)
    def startIPC(self):
        if self.ipc_running:
            logger.error("mpv ipc is already runing")
            return
        self.ipc_running = True
        while self.ipc_running and self.running and self.mpvThread.is_alive():
            try:
                time.sleep(2)
                if os.name == 'nt':
                    handler = _winapi.CreateFile(self.mpv_sock,
                        _winapi.GENERIC_READ | _winapi.GENERIC_WRITE, 0,
                        _winapi.NULL, _winapi.OPEN_EXISTING,
                        _winapi.FILE_FLAG_OVERLAPPED, _winapi.NULL
                    )
                    self.ipcSock = PipeConnection(handler)
                else:
                    self.ipcSock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                    self.ipcSock.connect(self.mpv_sock)
                cherrypy.engine.publish('mpvipc_start')
                self.setObserve()
            except Exception as e:
                logger.error("mpv ipc socket reconnecting")
                continue
            res = b''
            while self.ipc_running:
                try:
                    if os.name == 'nt':
                        data = self.ipcSock.recv_bytes(1048576)
                    else:
                        data = self.ipcSock.recv(1048576)
                    if data == b'': break
                    res += data
                    if data[-1] != 10: continue
                except Exception as e:
                    logger.debug(e)
                    break
                try:
                    msgs = res.decode().strip().split('\n')
                    for msg in msgs:
                        self.updateState(msg)
                except Exception as e:
                    logger.error("decode error "+str(msgs))
                finally:
                    res = b''
            self.ipcSock.close()
            logger.error("mpv ipc stopped")

    # start mpv thread
    def startMPV(self):
        while self.running:
            self.setState('TransportState', 'STOPPED')
            player_position = Setting.get(SettingProperty.PlayerPosition, default = 2)
            player_position_data = [[2,5],[2,98],[98,5],[98,98],[50,50]]
            x = player_position_data[player_position][0]
            y = player_position_data[player_position][1]
            params = [Setting.mpv_path, '--input-ipc-server={}'.format(self.mpv_sock),
                '--image-display-duration=inf', '--no-terminal', '--idle=yes', '--ontop', '--hwdec=yes',
                '--geometry={}%:{}%'.format(x, y),
                '--script-opts=osc-timetotal=yes,osc-layout=bottombar,osc-title=${title},osc-showwindowed=no,osc-seekbarstyle=bar,osc-visibility=auto'
            ]
            player_size = Setting.get(SettingProperty.PlayerSize, default = 1)
            if player_size <= 2:
                params.append('--autofit={}%'.format(2**player_size*10))
            elif player_size == 3:
                params.append('--autofit-larger=90%')
            elif player_size == 4:
                params.append('--fullscreen')
            if Setting.getSystem() == 'Darwin':
                params += [
                    '--ontop-level=system', '--on-all-workspaces',
                    '--macos-app-activation-policy=accessory',
                ]
                hw = Setting.get(SettingProperty.PlayerHW, default = 1)
                if hw == 0:
                    params.remove('--hwdec=yes')
                elif hw == 2:
                    params.append('--macos-force-dedicated-gpu=yes')
            logger.error("MPV started")
            cherrypy.engine.publish('mpv_start')
            self.proc = subprocess.run(params,
                stdout = subprocess.DEVNULL,
                stderr = subprocess.DEVNULL,
            )
            if self.running:
                time.sleep(1)
                logger.error("MPV restarting")

    def start(self):
        super(MPVRender, self).start()
        self.mpvThread = threading.Thread(target=self.startMPV, args=())
        self.mpvThread.start()
        self.ipcThread = threading.Thread(target=self.startIPC, args=())
        self.ipcThread.start()

    def stop(self):
        super(MPVRender, self).stop()
        logger.error("stoping mpv")
        while self.mpvThread.is_alive() and self.sendCommand(['quit']) is not True:
            logger.error("cannot send command quit to mpv")
            time.sleep(1)
        self.mpvThread.join()
        self.ipc_running = False
        self.ipcThread.join()
