# Copyright (c) 2021 by xfangfang. All Rights Reserved.

import sys
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

from .utils import loadXML, XMLPath, Setting, SettingProperty

if os.name == 'nt':
    import _winapi
    from multiprocessing.connection import PipeConnection

logger = logging.getLogger("Render")
logger.setLevel(logging.INFO)
SERVICE_STATE_OBSERVED = {
    "AVTransport": ['TransportState', 'TransportStatus'],
    "RenderingControl": ['Volume', 'Mute']
}


class ObserveProperty(Enum):
    volume = 1
    time_pos = 2
    pause = 3
    mute = 4
    duration = 5


class ObserveClient():
    def __init__(self, service, url, timeout=1800):
        self.url = url
        self.service = service
        self.startTime = int(time.time())
        self.sid = "uuid:{}".format(uuid.uuid4())
        self.timeout = timeout
        self.seq = 0
        self.host = re.findall(r"//([0-9:\.]*)", url)[0]
        self.path = re.findall(r"//[0-9:\.]*(.*)$", url)[0]
        print("-----------------------------", self.host)
        self.error = 0

    def isTimeout(self):
        return int(time.time()) - self.startTime > self.timeout

    def update(self, timeout=1800):
        self.startTime = int(time.time())
        self.timeout = timeout


class DataType(Enum):
    boolean = 'boolean'
    i2 = 'i2'
    ui2 = 'ui2'
    i4 = 'i4'
    ui4 = 'ui4'
    string = 'string'


class StateVariable:
    """The state of render
    """

    def __init__(self, name, sendEvents, datatype, service):
        self.name = name
        self.sendEvents = True if sendEvents == 'yes' else False
        self.datatype = DataType(datatype)
        self.minimum = None
        self.maximum = None
        self.allowedValueList = None
        self.value = '' if self.datatype == DataType.string else 0
        self.service = service

    def setAllowedValueList(self, values):
        self.allowedValueList = values

    def setAllowedValueRange(self, minimum, maximum):
        self.minimum = minimum
        self.maximum = maximum


class Argument:
    def __init__(self, name, state, value=None):
        self.name = name
        self.state = state
        self.value = value


class Action:
    """Operations supported by render.

    Parameters
    ----------
    name : string
        The name of the operation.
    input : list<Argument>
        A set of state values.
    output : list<Argument>
        A set of state values.

    """

    def __init__(self, name, input, output):
        self.name = name
        self.input = input
        self.output = output


class Render():
    """Media Renderer base class
    By inheriting this class,
    you can use a variety of players as media renderer
    see also: class MPVRender
    """

    def __init__(self):
        self.av_transport = ET.parse(XMLPath.AV_TRANSPORT.value).getroot()
        self.rendering_control = ET.parse(
            XMLPath.RENDERING_CONTROL.value).getroot()
        self.conection_manager = ET.parse(
            XMLPath.CONNECTION_MANAGER.value).getroot()
        self.action_response = ET.parse(
            XMLPath.ACTION_RESPONSE.value).getroot()
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
        self.setState('CurrentPlayMode', 'NORMAL')
        self.setState('TransportPlaySpeed', 1)
        self.setState('TransportStatus', 'OK')
        self.setState('RelativeCounterPosition', 2147483647)
        self.setState('AbsoluteCounterPosition', 2147483647)

    def addSubcribe(self, service, url, timeout=1800):
        """Add a DLNA client to subcribe list
        """
        logger.error("SUBSCRIBE: " + url)
        for client in self.eventSubcribes:
            if self.eventSubcribes[client].url == url and \
                    self.eventSubcribes[client].service == service:
                s = self.eventSubcribes[client]
                s.update(timeout)
                logger.error("SUBSCRIBE UPDATE")
                return {
                    "SID": s.sid,
                    "TIMEOUT": "Second-{}".format(s.timeout)
                }
        logger.error("SUBSCRIBE ADD")
        client = ObserveClient(service, url, timeout)
        self.eventSubcribes[client.sid] = client
        threading.Thread(target=self._sendInitEvent,
                         kwargs={
                             'service': service,
                             'client': client
                         }).start()
        return {
            "SID": client.sid,
            "TIMEOUT": "Second-{}".format(client.timeout)
        }

    def _sendInitEvent(self, service, client):
        time.sleep(1)
        self.stateChangeEvent.wait()
        for state in SERVICE_STATE_OBSERVED[service]:
            self.stateChangeList[state] = self.stateList[state]
        self.stateSetEvent.set()

    def removeSubcribe(self, sid):
        """Remove a DLNA client from subcribe list
        """
        if sid in self.eventSubcribes:
            del self.eventSubcribes[sid]
            return 200
        return 412

    def renewSubcribe(self, sid, timeout=1800):
        """Renew a DLNA client in subcribe list
        """
        if sid in self.eventSubcribes:
            self.eventSubcribes[sid].update(timeout)
            return 200
        return 412

    def _sendEventCallback(self, host, path, headers, data):
        """Sending event
        """
        root = copy.deepcopy(self.event_response)
        lastChange = ET.SubElement(root[0], 'LastChange')
        event = ET.Element('Event')
        event.attrib['xmlns'] = 'urn:schemas-upnp-org:metadata-1-0/AVT/'
        instanceID = ET.SubElement(event, 'InstanceID')
        instanceID.set('val', '0')
        for i in data:
            p = ET.SubElement(instanceID, i)
            p.set('val', str(data[i].value))
        lastChange.text = ET.tostring(event, encoding="UTF-8").decode()
        data = ET.tostring(root, encoding="UTF-8", xml_declaration=True)
        logger.debug("Prop Change---------")
        logger.debug(data)
        conn = http.client.HTTPConnection(host, timeout=5)
        conn.request("NOTIFY", path, data, headers)
        conn.close()

    def _eventCallback(self, stateChangeList):
        """Sending event to DLNA client in subcribe list
        """
        if not bool(stateChangeList):
            return
        removeList = []
        for sid in self.eventSubcribes:
            client = self.eventSubcribes[sid]
            if client.isTimeout():
                removeList.append(client.sid)
                continue
            try:
                # Only send state which within the service
                state = {}
                for name in stateChangeList:
                    if self.stateList[name].service == client.service:
                        state[name] = stateChangeList[name]
                if len(state) == 0:
                    continue

                self._sendEventCallback(
                    client.host, client.path, {
                        "NT":
                        "upnp:event",
                        "NTS":
                        "upnp:propchange",
                        "Content-Type":
                        'text/xml; charset="utf-8"',
                        "SERVER":
                        "{}/{} UPnP/1.0 Macast/{}".format(
                            Setting.getSystem(), Setting.getSystemVersion(),
                            Setting.getVersion()),
                        "SID":
                        client.sid,
                        "SEQ":
                        client.seq,
                        "TIMEOUT":
                        "Second-{}".format(client.timeout)
                    }, state)
                client.seq = client.seq + 1
            except Exception as e:
                logger.error("send event error: " + str(e))
                client.error = client.error + 1
                if client.error > 10:
                    logger.debug("remove " + client.sid)
                    removeList.append(client.sid)
        for sid in removeList:
            self.removeSubcribe(sid)

    def event(self):
        """Render Event thread
        If a DLNA client subscribes to the render event,
        it will automatically send the event to the client every second
        when the player state changes.
        """
        while self.running:
            self.stateSetEvent.wait()
            if not self.running:
                return
            self.stateChangeEvent.clear()
            if bool(self.eventSubcribes):
                self._eventCallback(self.stateChangeList)
            self.stateChangeList = {}
            self.stateSetEvent.clear()
            self.stateChangeEvent.set()

    def call(self, rawbody):
        """Processing requests from DLNA clients
        The request from the client is passed into this method
        through the DLNAHandler(macast.py -> class DLNAHandler).
        If the Render class implements the corresponding action method,
        the method will be called automatically.
        Otherwise, the corresponding state variable will be returned
        according to the **action return value** described in the XML file.
        """
        root = ET.fromstring(rawbody)[0][0]
        param = {}
        for node in root:
            param[node.tag] = node.text
        logger.debug(param)
        action = root.tag.split('}')[1]
        service = root.tag.split(":")[3]
        method = "{}_{}".format(service, action)
        if method not in [
            'AVTransport_GetPositionInfo',
            'AVTransport_GetTransportInfo',
            'RenderingControl_GetVolume'
        ]:
            logger.info(method)
        res = {}
        if hasattr(self, method):
            data = {}
            input = self.actionList[service][action].input
            for arg in input:
                data[arg.name] = Argument(
                    arg.name, arg.state,
                    param[arg.name] if arg.name in param else None)
                if arg.name in param:
                    self.setState(arg.state, param[arg.name])
            res = getattr(self, method)(data)
        else:
            output = self.actionList[service][action].output
            for arg in output:
                res[arg.name] = self.stateList[arg.state].value

        # build response xml
        root = copy.deepcopy(self.action_response)
        ns = 'urn:schemas-upnp-org:service:{}:1'.format(service)
        response = ET.SubElement(root[0],
                                 '{{{}}}{}Response'.format(ns, action))
        for key in res:
            prop = ET.SubElement(response, key)
            prop.text = str(res[key])
        return ET.tostring(root, encoding="UTF-8", xml_declaration=True)

    def setState(self, name, value):
        """Set states of the render
        When the statistical state changes, this method will be blocked
        Every time this method is called, the event thread will be informed
        of the state change through self.stateSetEvent
        """
        if self.stateList[name].value == value:
            return
        self.stateList[name].value = value
        if name in SERVICE_STATE_OBSERVED['AVTransport'] or \
                name in SERVICE_STATE_OBSERVED['RenderingControl']:
            self.stateChangeEvent.wait()
            self.stateChangeList[name] = self.stateList[name]
            self.stateSetEvent.set()

    def getState(self, name):
        """Get various states of the render
        The type of state is described by XML file
        """
        return self.stateList[name].value

    def _buildAction(self, service, xml):
        """Build action and variable list from xml file
        """
        ns = '{urn:schemas-upnp-org:service-1-0}'
        # get state variable from xml file
        for stateVariable in xml.iter(ns + 'stateVariable'):
            name = stateVariable.find(ns + "name").text
            data = StateVariable(name,
                                 stateVariable.attrib['sendEvents'],
                                 stateVariable.find(ns + "dataType").text,
                                 service)
            allowedValueList = stateVariable.find(ns + "allowedValueList")
            if allowedValueList is not None:
                values = [
                    value.text
                    for value in allowedValueList.findall(ns + "allowedValue")
                ]
                data.setAllowedValueList(values)

            allowedValueRange = stateVariable.find(ns + "allowedValueRange")
            if allowedValueRange is not None:
                data.setAllowedValueRange(
                    int(allowedValueRange.find(ns + "minimum").text),
                    int(allowedValueRange.find(ns + "maximum").text))
            self.stateList[name] = data

        # get action from xml file
        actions = {}
        for action in xml.iter(ns + 'action'):
            name = action.find(ns + "name").text
            input = []
            output = []
            argumentList = action.find(ns + "argumentList")
            if argumentList is not None:
                for argument in argumentList.findall(ns + 'argument'):
                    data = Argument(
                        argument.find(ns + "name").text,
                        argument.find(ns + "relatedStateVariable").text)
                    if argument.find(ns + "direction").text == 'in':
                        input.append(data)
                    else:
                        output.append(data)
            actions[name] = Action(name, input, output)
        self.actionList[service] = actions

    def start(self):
        """Start render thread
        """
        if not self.running:
            self.running = True
            self.eventThread = threading.Thread(target=self.event, daemon=True)
            self.eventThread.start()
        else:
            return

    def stop(self):
        """Stop render thread
        """
        self.running = False
        self.stateChangeEvent.set()
        self.stateSetEvent.set()


class MPVRender(Render):
    """
      When the DLNA client accesses, MPVRender will returns the state value
    corresponding to "out" section in the action specified in the service XML
    file by default.
      When some "service_action" methods are implemented
    (such as "RenderingControl_SetVolume"), the DLNA client's access will be
    automatically directed to these methods
    """

    def __init__(self):
        super(MPVRender, self).__init__()
        if os.name == 'nt':
            self.mpv_sock = Setting.getPath(r"\\.\pipe\macast_mpvsocket")
        else:
            self.mpv_sock = '/tmp/macast_mpvsocket'
        self.proc = None
        self.mpvThread = None
        self.ipcThread = None
        self.ipcSock = None
        self.pause = False  # changed with pause action
        self.playing = False  # changed with start and stop
        self.ipc_running = False
        self.ipc_once_connected = False
        # As long as IPC has been connected, the ipc_once_connected is True
        # When the ipc_once_connected is True, it shows that there is no error
        # in the starting parameters of MPV, and there is no need to wait for
        # one second to restart MPV.
        self.commandLock = threading.Lock()

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
        uri = data['CurrentURI'].value
        self.setState('AVTransportURI', uri)
        self.sendCommand(['loadfile', uri, 'replace'])
        meta = ET.fromstring(data['CurrentURIMetaData'].value)
        meta_text = ET.tostring(meta, encoding="UTF-8").decode()
        self.setState('AVTransportURIMetaData', meta_text)
        self.setState('CurrentTrackMetaData', meta_text)
        logger.info(uri)
        title = Setting.getFriendlyName()
        titleXML = meta.find('.//{{{}}}title'.format(meta.nsmap['dc']))
        if titleXML is not None and titleXML.text is not None:
            title = titleXML.text
        self.sendCommand(['set_property', 'title', title])
        self.sendCommand(['set_property', 'pause', False])
        self.setState('RelativeTimePosition', '00:00:00')
        self.setState('AbsoluteTimePosition', '00:00:00')
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
        target = data['Target']
        self.sendCommand(['seek', target.value, 'absolute'])
        self.setState('RelativeTimePosition', target.value)
        self.setState('AbsoluteTimePosition', target.value)
        return {}

    def AVTransport_Stop(self, data):
        self.sendCommand(['stop'])
        self.setState('TransportState', 'STOPPED')
        return {}

    def setObserve(self):
        """Set several property that needed observe
        """
        self.sendCommand(
            ['observe_property', ObserveProperty.volume.value, 'volume'])
        self.sendCommand(
            ['observe_property', ObserveProperty.time_pos.value, 'time-pos'])
        self.sendCommand(
            ['observe_property', ObserveProperty.pause.value, 'pause'])
        self.sendCommand(
            ['observe_property', ObserveProperty.mute.value, 'mute'])
        self.sendCommand(
            ['observe_property', ObserveProperty.duration.value, 'duration'])

    def updateState(self, res):
        """Update player state from mpv
        """
        res = json.loads(res)
        if 'id' in res:
            if res['id'] == ObserveProperty.volume.value:
                logger.info(res)
                if 'data' in res and res['data'] is not None:
                    self.setState('Volume', int(res['data']))
            elif res['id'] == ObserveProperty.time_pos.value:
                if 'data' not in res or res['data'] is None:
                    time = '00:00:00'
                else:
                    sec = int(res['data'])
                    time = '%d:%02d:%02d' % (sec // 3600,
                                             (sec % 3600) // 60, sec % 60)
                self.setState('RelativeTimePosition', time)
                self.setState('AbsoluteTimePosition', time)
            elif res['id'] == ObserveProperty.pause.value:
                logger.info(res)
                if self.playing is False:
                    return
                if res['data'] and res['data'] is not None:
                    self.pause = True
                    state = "PAUSED_PLAYBACK"
                else:
                    self.pause = False
                    state = "PLAYING"
                self.setState('TransportState', state)
            elif res['id'] == ObserveProperty.mute.value:
                self.setState('Mute', res['data'])
            elif res['id'] == ObserveProperty.duration.value:
                if 'data' not in res or res['data'] is None:
                    time = '00:00:00'
                else:
                    sec = int(res['data'])
                    time = '%d:%02d:%02d' % (sec // 3600,
                                             (sec % 3600) // 60, sec % 60)
                    cherrypy.engine.publish('mpv_update_duration', time)
                    logger.info("update duration " + time)
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
                if res.get('file_error', False):
                    cherrypy.engine.publish('notify',
                                            "File error",
                                            res['file_error'])
            elif res['event'] == 'start-file':
                self.playing = True
                self.setState('TransportState', 'TRANSITIONING')
                self.setState('TransportStatus', 'OK')
                cherrypy.engine.publish('mpv_av_uri',
                                        self.getState('AVTransportURI'))
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

    def sendCommand(self, command):
        """Sending command to mpv
        """
        logger.debug("send command: " + str(command))
        data = {"command": command}
        msg = json.dumps(data) + '\n'
        try:
            self.commandLock.acquire()
            if os.name == 'nt':
                self.ipcSock.send_bytes(msg.encode())
            else:
                self.ipcSock.sendall(msg.encode())
            return True
        except Exception as e:
            logger.error('sendCommand: ' + str(e))
            return False
        finally:
            self.commandLock.release()

    def startIPC(self):
        """Start ipc thread
        Communicating with mpv
        """
        if self.ipc_running:
            logger.error("mpv ipc is already runing")
            return
        self.ipc_running = True
        while self.ipc_running and self.running and self.mpvThread.is_alive():
            try:
                time.sleep(0.5)
                logger.error("mpv ipc socket start connect")
                if os.name == 'nt':
                    handler = _winapi.CreateFile(
                        self.mpv_sock,
                        _winapi.GENERIC_READ | _winapi.GENERIC_WRITE, 0,
                        _winapi.NULL, _winapi.OPEN_EXISTING,
                        _winapi.FILE_FLAG_OVERLAPPED, _winapi.NULL)
                    self.ipcSock = PipeConnection(handler)
                else:
                    self.ipcSock = socket.socket(socket.AF_UNIX,
                                                 socket.SOCK_STREAM)
                    self.ipcSock.connect(self.mpv_sock)
                cherrypy.engine.publish('mpvipc_start')
                self.ipc_once_connected = True
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
                    if data == b'':
                        break
                    res += data
                    if data[-1] != 10:
                        continue
                except Exception as e:
                    logger.debug(e)
                    break
                try:
                    msgs = res.decode().strip().split('\n')
                    for msg in msgs:
                        self.updateState(msg)
                except Exception as e:
                    logger.error("decode error " + str(msgs))
                finally:
                    res = b''
            self.ipcSock.close()
            logger.error("mpv ipc stopped")

    def startMPV(self):
        """Start mpv thread
        """
        error_time = 3
        while self.running and error_time > 0:
            self.setState('TransportState', 'STOPPED')
            player_position = Setting.get(SettingProperty.PlayerPosition,
                                          default=2)
            player_position_data = [[2, 5], [2, 98], [98, 5], [98, 98],
                                    [50, 50]]
            x = player_position_data[player_position][0]
            y = player_position_data[player_position][1]
            params = [
                Setting.mpv_path,
                '--input-ipc-server={}'.format(self.mpv_sock),
                '--image-display-duration=inf',
                '--idle=yes',
                '--no-terminal',
                '--ontop',
                '--on-all-workspaces',
                '--hwdec=yes',
                '--geometry={}%:{}%'.format(x, y),
                '--save-position-on-quit=yes',
                '--script-opts=osc-timetotal=yes,osc-layout=bottombar,' +
                'osc-title=${title},osc-showwindowed=no,' +
                'osc-seekbarstyle=bar,osc-visibility=auto'
            ]
            scripts_path = Setting.getPath(
                os.path.join(os.path.dirname(__file__), 'scripts'))
            if os.path.exists(scripts_path):
                scripts = os.listdir(scripts_path)
                scripts = filter(lambda s: s.endswith('.lua'), scripts)
                for script in scripts:
                    path = os.path.join(scripts_path, script)
                    params.append('--script={}'.format(path))
            player_size = Setting.get(SettingProperty.PlayerSize, default=1)
            if player_size <= 2:
                params.append('--autofit={}%'.format(
                    int(15 - 2.5 * player_size + 7.5 * player_size**2)))
            elif player_size == 3:
                params.append('--autofit-larger=90%')
            elif player_size == 4:
                params.append('--fullscreen')
            if sys.platform == 'darwin':
                params += [
                    '--ontop-level=system',
                    '--on-all-workspaces',
                    '--macos-app-activation-policy=accessory',
                ]
                hw = Setting.get(SettingProperty.PlayerHW, default=1)
                if hw == 0:
                    params.remove('--hwdec=yes')
                elif hw == 2:
                    params.append('--macos-force-dedicated-gpu=yes')
            logger.error("MPV started")
            cherrypy.engine.publish('mpv_start')
            self.proc = subprocess.run(
                params,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                stdin=subprocess.PIPE)

            logger.error("MPV stopped")
            if self.running and not self.ipc_once_connected:
                # There should be a problem with the MPV startup parameters
                time.sleep(1)
                error_time -= 1
                logger.error("MPV restarting")
        if error_time <= 0:
            # some thing wrong with mpv
            cherrypy.engine.publish('mpv_error')
            logger.error("MPV cannot start")

    def start(self):
        """Start mpv and mpv ipc
        """
        super(MPVRender, self).start()
        self.mpvThread = threading.Thread(target=self.startMPV, args=())
        self.mpvThread.start()
        self.ipcThread = threading.Thread(target=self.startIPC, args=())
        self.ipcThread.start()

    def stop(self):
        """Stop mpv and mpv ipc
        """
        super(MPVRender, self).stop()
        logger.error("stoping mpv")
        while self.mpvThread.is_alive() and self.sendCommand(['quit'
                                                              ]) is not True:
            logger.error("cannot send command quit to mpv")
            time.sleep(1)
        self.mpvThread.join()
        self.ipc_running = False
        self.ipcThread.join()
