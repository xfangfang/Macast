# Copyright (c) 2021 by xfangfang. All Rights Reserved.

import re
import time
import uuid
import gettext
import http.client
import logging
import threading
from lxml import etree
from queue import Queue
from enum import Enum

from .utils import loadXML, XMLPath, Setting


logger = logging.getLogger("Renderer")
logger.setLevel(logging.INFO)
SERVICE_STATE_OBSERVED = {
    "AVTransport": ['TransportState',
                    'TransportStatus',
                    'CurrentMediaDuration',
                    'CurrentTrackDuration',
                    'CurrentTrack',
                    'NumberOfTracks'],
    "RenderingControl": ['Volume', 'Mute'],
    "ConnectionManager": ['A_ARG_TYPE_Direction',
                          'SinkProtocolInfo',
                          'CurrentConnectionIDs']
}


class ObserveClient:
    def __init__(self, service, url, timeout=1800):
        self.url = url
        self.service = service
        self.startTime = int(time.time())
        self.sid = "uuid:{}".format(uuid.uuid4())
        self.timeout = timeout
        self.seq = 0
        self.host = re.findall(r"//([0-9:.]*)", url)[0]
        self.path = re.findall(r"//[0-9:.]*(.*)$", url)[0]
        print("-----------------------------", self.host)
        self.error = 0

    def is_timeout(self):
        return int(time.time()) - self.startTime > self.timeout

    def update(self, timeout=1800):
        self.startTime = int(time.time())
        self.timeout = timeout

    def send_event_callback(self, data):
        """Sending event data to client
        """
        headers = {"NT": "upnp:event",
                   "NTS": "upnp:propchange",
                   "CONTENT-TYPE": 'text/xml; charset="utf-8"',
                   "SERVER": Setting.get_server_info(),
                   "SID": self.sid,
                   "SEQ": self.seq,
                   "TIMEOUT": "Second-{}".format(self.timeout)
                   }
        namespace = 'urn:schemas-upnp-org:event-1-0'
        root = etree.Element(etree.QName(namespace, 'propertyset'),
                             nsmap={'e': namespace})
        if self.service == 'ConnectionManager':
            for i in data:
                prop = etree.SubElement(
                    root, '{urn:schemas-upnp-org:event-1-0}property')
                item = etree.SubElement(prop, i)
                item.text = str(data[i])
        else:
            prop = etree.SubElement(
                root, '{urn:schemas-upnp-org:event-1-0}property')
            last_change = etree.SubElement(prop, 'LastChange')
            event = etree.Element('Event')
            event.attrib['xmlns'] = 'urn:schemas-upnp-org:metadata-1-0/AVT/'
            instance_id = etree.SubElement(event, 'InstanceID')
            instance_id.set('val', '0')
            for i in data:
                p = etree.SubElement(instance_id, i)
                p.set('val', str(data[i]))
            last_change.text = etree.tostring(event, encoding="UTF-8").decode()
        data = etree.tostring(root, encoding="UTF-8")
        logger.debug("Prop Change---------")
        logger.debug(data)
        conn = http.client.HTTPConnection(self.host, timeout=5)
        conn.request("NOTIFY", self.path, data, headers)
        conn.close()
        self.seq = self.seq + 1


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

    def __init__(self, name, send_events, datatype, service):
        self.name = name
        self.sendEvents = True if send_events == 'yes' else False
        self.datatype = DataType(datatype)
        self.minimum = None
        self.maximum = None
        self.allowedValueList = None
        self.value = '' if self.datatype == DataType.string else 0
        self.service = service

    def set_allowed_value_list(self, values):
        self.allowedValueList = values
        if 'NOT_IMPLEMENTED' in values:
            self.value = 'NOT_IMPLEMENTED'

    def set_allowed_value_range(self, minimum, maximum):
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


class Renderer:
    """Media Renderer base class
    By inheriting this class,
    you can use a variety of players as media renderer
    see also: class MPVRender
    """
    support_platform = set()

    def __init__(self, lang=gettext.gettext):
        global _
        _ = lang
        self.av_transport = etree.parse(XMLPath.AV_TRANSPORT.value).getroot()
        self.rendering_control = etree.parse(
            XMLPath.RENDERING_CONTROL.value).getroot()
        self.connection_manager = etree.parse(
            XMLPath.CONNECTION_MANAGER.value).getroot()
        self.running = False
        self.state_list = {}
        self.action_list = {}
        self.event_thread = None
        self.event_subscribes = {}  # subscribe devices
        self.state_queue = Queue()  # states needed be send to subscribe devices
        self.removed_device_queue = Queue()  # devices needed be removed
        self.append_device_queue = Queue()  # devices needed be added
        self._build_action('AVTransport', self.av_transport)
        self._build_action('RenderingControl', self.rendering_control)
        self._build_action('ConnectionManager', self.connection_manager)
        self.renderer_setting = RendererSetting()
        # set default value
        self.set_state('CurrentPlayMode', 'NORMAL')
        self.set_state('TransportPlaySpeed', 1)
        self.set_state('TransportStatus', 'OK')
        self.set_state('RelativeCounterPosition', 2147483647)
        self.set_state('AbsoluteCounterPosition', 2147483647)
        self.set_state('A_ARG_TYPE_Direction', 'Output')
        self.set_state('CurrentConnectionIDs', '0')
        self.set_state('PlaybackStorageMedium', 'None')
        self.set_state('SinkProtocolInfo', loadXML(XMLPath.PROTOCOL_INFO.value))

    def add_subscribe(self, service, url, timeout=1800):
        """Add a DLNA client to subscribe list
        """
        logger.error("SUBSCRIBE: " + url)
        for client in self.event_subscribes:
            if self.event_subscribes[client].url == url and \
                    self.event_subscribes[client].service == service:
                s = self.event_subscribes[client]
                s.update(timeout)
                logger.error("SUBSCRIBE UPDATE")
                return {
                    "SID": s.sid,
                    "TIMEOUT": "Second-{}".format(s.timeout)
                }
        logger.error("SUBSCRIBE ADD")
        client = ObserveClient(service, url, timeout)
        self.append_device_queue.put(client)
        threading.Thread(target=self._send_init_event,
                         kwargs={
                             'service': service,
                             'client': client
                         }).start()
        return {
            "SID": client.sid,
            "TIMEOUT": "Second-{}".format(client.timeout)
        }

    def _send_init_event(self, service, client):
        """When there is a client subscription,
        the first event sends all the state values of the service.
        """
        data = {}
        for state in SERVICE_STATE_OBSERVED[service]:
            data[state] = self.state_list[state].value
        client.send_event_callback(data)

    def remove_subscribe(self, sid):
        """Remove a DLNA client from subscribe list
        """
        if sid in self.event_subscribes:
            self.removed_device_queue.put(sid)
        return 200

    def renew_subcribe(self, sid, timeout=1800):
        """Renew a DLNA client in subcribe list
        """
        if sid in self.event_subscribes:
            self.event_subscribes[sid].update(timeout)
            return 200
        return 412

    def _event_callback(self, state_change_list):
        """Sending different states in the stateChangeList to the clients
        that subscribe to them.
        """
        if not bool(state_change_list):
            return
        # remove clients
        while not self.removed_device_queue.empty():
            sid = self.removed_device_queue.get()
            logger.info("Remove client: {}".format(sid))
            del self.event_subscribes[sid]
            self.removed_device_queue.task_done()
        # add clients
        while not self.append_device_queue.empty():
            client = self.append_device_queue.get()
            self.event_subscribes[client.sid] = client
            self.append_device_queue.task_done()
        # send stateChangeList to client
        for sid in self.event_subscribes:
            client = self.event_subscribes[sid]
            if client.is_timeout():
                self.remove_subscribe(client.sid)
                continue
            try:
                # Only send state which within the service
                state = {}
                for name in state_change_list:
                    if self.state_list[name].service == client.service:
                        state[name] = state_change_list[name]
                if len(state) == 0:
                    continue
                client.send_event_callback(state)

            except Exception as e:
                logger.error("send event error: " + str(e))
                client.error = client.error + 1
                if client.error > 10:
                    logger.debug("remove " + client.sid)
                    self.remove_subscribe(client.sid)

    def event(self):
        """Render Event thread
        If a DLNA client subscribes to the render event,
        it will automatically send the event to the client every second
        when the player state changes.
        """
        while self.running:
            if not self.state_queue.empty():
                state = {}
                while not self.state_queue.empty():
                    k, v = self.state_queue.get()
                    state[k] = v
                    self.state_queue.task_done()
                self._event_callback(state)
            time.sleep(1)

    def call(self, rawbody):
        """Processing requests from DLNA clients
        The request from the client is passed into this method
        through the DLNAHandler(macast.py -> class DLNAHandler).
        If the Render class implements the corresponding action method,
        the method will be called automatically.
        Otherwise, the corresponding state variable will be returned
        according to the **action return value** described in the XML file.
        """
        root = etree.fromstring(rawbody)[0][0]
        param = {}
        for node in root:
            param[node.tag] = node.text
        action = root.tag.split('}')[1]
        service = root.tag.split(":")[3]
        method = "{}_{}".format(service, action)
        if method not in [
            'AVTransport_GetPositionInfo',
            'AVTransport_GetTransportInfo',
            'RenderingControl_GetVolume'
        ]:
            logger.info("{} {}".format(method, param))
        res = {}
        if hasattr(self, method):
            data = {}
            input = self.action_list[service][action].input
            for arg in input:
                data[arg.name] = Argument(
                    arg.name, arg.state,
                    param[arg.name] if arg.name in param else None)
                if arg.name in param:
                    self.set_state(arg.state, param[arg.name])
            res = getattr(self, method)(data)
        else:
            output = self.action_list[service][action].output
            for arg in output:
                res[arg.name] = self.state_list[arg.state].value

        # build response xml
        ns = 'http://schemas.xmlsoap.org/soap/envelope/'
        encoding = 'http://schemas.xmlsoap.org/soap/encoding/'
        root = etree.Element(etree.QName(ns, 'Envelope'), nsmap={'s': ns})
        root.attrib['{{{}}}encodingStyle'.format(ns)] = encoding
        body = etree.SubElement(root, etree.QName(ns, 'Body'), nsmap={'s': ns})
        namespace = 'urn:schemas-upnp-org:service:{}:1'.format(service)
        response = etree.SubElement(body,
                                    etree.QName(
                                        namespace, '{}Response'.format(action)),
                                    nsmap={'u': namespace})
        for key in res:
            prop = etree.SubElement(response, key)
            prop.text = str(res[key])
        return etree.tostring(root, encoding="UTF-8", xml_declaration=True)

    def set_state(self, name, value):
        """Set states of the render
        """
        # update states which will send to DLNA Client
        if name in SERVICE_STATE_OBSERVED['AVTransport'] or \
                name in SERVICE_STATE_OBSERVED['RenderingControl']:
            logger.debug("setState: {} {}".format(name, value))
            self.state_queue.put((name, value))
        # update other states
        if self.state_list[name].value != value:
            self.state_list[name].value = value

    def get_state(self, name):
        """Get various states of the render
        The type of state is described by XML file
        """
        return self.state_list[name].value

    def _build_action(self, service, xml):
        """Build action and variable list from xml file
        """
        ns = '{urn:schemas-upnp-org:service-1-0}'
        # get state variable from xml file
        for state_variable in xml.iter(ns + 'stateVariable'):
            name = state_variable.find(ns + "name").text
            data = StateVariable(name,
                                 state_variable.attrib['sendEvents'],
                                 state_variable.find(ns + "dataType").text,
                                 service)
            allowed_value_list = state_variable.find(ns + "allowedValueList")
            if allowed_value_list is not None:
                values = [
                    value.text
                    for value in allowed_value_list.findall(ns + "allowedValue")
                ]
                data.set_allowed_value_list(values)

            allowed_value_range = state_variable.find(ns + "allowedValueRange")
            if allowed_value_range is not None:
                data.set_allowed_value_range(
                    int(allowed_value_range.find(ns + "minimum").text),
                    int(allowed_value_range.find(ns + "maximum").text))
            self.state_list[name] = data

        # get action from xml file
        actions = {}
        for action in xml.iter(ns + 'action'):
            name = action.find(ns + "name").text
            input = []
            output = []
            argument_list = action.find(ns + "argumentList")
            if argument_list is not None:
                for argument in argument_list.findall(ns + 'argument'):
                    data = Argument(
                        argument.find(ns + "name").text,
                        argument.find(ns + "relatedStateVariable").text)
                    if argument.find(ns + "direction").text == 'in':
                        input.append(data)
                    else:
                        output.append(data)
            actions[name] = Action(name, input, output)
        self.action_list[service] = actions

    def start(self):
        """Start render thread
        """
        if not self.running:
            self.running = True
            self.event_thread = threading.Thread(target=self.event, daemon=True)
            self.event_thread.start()
            self.set_state('TransportState', 'STOPPED')
        else:
            return

    def stop(self):
        """Stop render thread
        """
        self.running = False

    # The following method names are defined by the XML file

    def RenderingControl_SetVolume(self, data):
        volume = data['DesiredVolume']
        self.set_media_volume(volume.value)
        return {}

    def RenderingControl_SetMute(self, data):
        mute = data['DesiredMute']
        if mute.value == 0 or mute.value == '0':
            mute = False
        else:
            mute = True
        self.set_media_mute(mute)
        return {}

    def AVTransport_SetAVTransportURI(self, data):
        uri = data['CurrentURI'].value
        logger.info(uri)
        self.set_state('AVTransportURI', uri)
        self.set_media_url(uri)
        try:
            meta = etree.fromstring(data['CurrentURIMetaData'].value.encode())
            title = Setting.get_friendly_name()
            title_xml = meta.find('.//{{{}}}title'.format(meta.nsmap['dc']))
            if title_xml is not None and title_xml.text is not None:
                title = title_xml.text
            self.set_media_title(title)
            metadata = etree.tostring(
                meta, encoding="UTF-8", xml_declaration=True)
        except Exception as e:
            logger.error(str(e))
            self.set_state('CurrentTrackMetaData', data['CurrentURIMetaData'].value)
        else:
            self.set_state('CurrentTrackMetaData', metadata)
        self.set_media_resume()
        self.set_state('CurrentTrackURI', uri)
        self.set_state('RelativeTimePosition', '00:00:00')
        self.set_state('AbsoluteTimePosition', '00:00:00')
        return {}

    def AVTransport_Play(self, data):
        self.set_media_resume()
        self.set_state('TransportState', 'PLAYING')
        self.set_state('TransportStatus', 'OK')
        return {}

    def AVTransport_Pause(self, data):
        self.set_media_pause()
        self.set_state('TransportState', 'PAUSED_PLAYBACK')
        return {}

    def AVTransport_Seek(self, data):
        target = data['Target']
        self.set_media_position(target.value)
        self.set_state('RelativeTimePosition', target.value)
        self.set_state('AbsoluteTimePosition', target.value)
        return {}

    def AVTransport_Stop(self, data):
        self.set_media_stop()
        self.set_state('TransportState', 'STOPPED')
        return {}

    # If you want a new player renderer, please rewrite the
    # following methods. For details, please refer to MPVRender

    def reload(self):
        self.stop()
        self.start()

    def set_media_stop(self):
        pass

    def set_media_pause(self):
        pass

    def set_media_resume(self):
        pass

    def set_media_volume(self, data):
        """ data : int, range from 0 to 100
        """
        pass

    def set_media_mute(self, data):
        """ data : bool
        """
        pass

    def set_media_url(self, data):
        """ data : string
        """
        pass

    def set_media_title(self, data):
        """ data : string
        """
        pass

    def set_media_position(self, data):
        """ data : string position, 00:00:00
        """
        pass

    # The following methods are usually used to update the states of
    # DLNA Renderer according to the status obtained from the player.
    # The DLNA client will choose when to obtain this information.

    def set_state_position(self, data):
        """ data : string position, 00:00:00
        """
        self.set_state('RelativeTimePosition', data)
        self.set_state('AbsoluteTimePosition', data)

    def set_state_duration(self, data):
        """ data : string position, 00:00:00
        """
        self.set_state('CurrentTrackDuration', data)
        self.set_state('CurrentMediaDuration', data)

    def set_state_transport(self, data):
        """data : string in [PLAYING, PAUSED_PLAYBACK, STOPPED,
                    NO_MEDIA_PRESENT, TRANSITIONING]
        """
        self.set_state('TransportState', data)
        self.set_state('TransportStatus', 'OK')

    def set_state_transport_error(self):
        self.set_state('TransportState', 'STOPPED')
        self.set_state('TransportStatus', 'ERROR_OCCURRED')

    def set_state_mute(self, data):
        """ data : bool
        """
        self.set_state('Mute', data)

    def set_state_volume(self, data):
        """ data : int, range from 0 to 100
        """
        self.set_state('Volume', data)


class RendererSetting:
    def build_menu(self):
        return []
