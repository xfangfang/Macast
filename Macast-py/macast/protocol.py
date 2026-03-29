# Copyright (c) 2021 by xfangfang. All Rights Reserved.
import json
import os
import re
import sys
import time
import uuid
import http.client
import logging
import cherrypy
import threading

import requests
from lxml import etree
from queue import Queue
from enum import Enum
from cherrypy import _cpnative_server

from .utils import load_xml, XMLPath, Setting, cherrypy_publish, SETTING_DIR

logger = logging.getLogger("Protocol")
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


class Protocol:
    def __init__(self):
        self._handler = None

    @property
    def handler(self):
        if self._handler is None:
            self._handler = Handler()
        return self._handler

    def start(self):
        pass

    def stop(self):
        pass

    def reload(self):
        self.stop()
        self.start()

    def methods(self):
        return list(filter(lambda m: m.startswith('set_state_') and callable(getattr(self, m)), dir(self)))

    @property
    def renderer(self):
        renderers = cherrypy.engine.publish('get_renderer')
        if len(renderers) == 0:
            logger.error("Unable to find an available renderer.")
            return None
        return renderers.pop()

    # The following methods are called by the renderer to set the playback status within the protocol,
    # which will be passed to the client (generally the mobile phone)

    def set_state_position(self, data: str):
        """
        :param data: string, eg: 00:00:00
        :return:
        """
        pass

    def set_state_duration(self, data: str):
        """
        :param data: string, eg: 00:00:00
        :return:
        """
        pass

    def set_state_pause(self):
        """
        :return:
        """
        pass

    def set_state_play(self):
        """
        :return:
        """
        pass

    def set_state_stop(self):
        """
        :return:
        """
        pass

    def set_state_eof(self):
        """
        :return:
        """
        pass

    def set_state_transport(self, data: str):
        """
        :param data: string in [PLAYING, PAUSED_PLAYBACK, STOPPED, NO_MEDIA_PRESENT]
        :return:
        """
        pass

    def set_state_transport_error(self):
        """
        :return:
        """
        pass

    def set_state_mute(self, data: bool):
        """
        :param data: bool
        :return:
        """
        pass

    def set_state_volume(self, data: int):
        """
        :param data: int 0-100
        :return:
        """
        pass

    def set_state_speed(self, data: str):
        pass

    def set_state_display_subtitle(self, data: bool):
        """ set custom subtitle file path
        :param data: bool, whether display the subtitle
        :return:
        """
        pass

    def set_state_url(self, data: str):
        pass

    def set_state(self, state_name, state_value):
        pass

    def get_state(self, state_name):
        return ''

    def get_state_title(self) -> str:
        """
        :return: string, eg: demo
        """
        return ''

    def get_state_url(self) -> str:
        """
        :return: string, eg: http://10.10.10.10/demo.mp4
        """
        return ''

    def get_state_position(self) -> str:
        """
        :return: string, eg: 00:00:00
        """
        return '00:00:00'

    def get_state_duration(self) -> str:
        """
        :return: string, eg: 00:00:00
        """
        return '00:00:00'

    def get_state_volume(self) -> int:
        """
        :return: int, range from 0 to 100
        """
        return 80

    def get_state_mute(self) -> bool:
        """
        :return: bool
        """
        return False

    def get_state_transport_state(self) -> str:
        """
        :return: string in [PLAYING, PAUSED_PLAYBACK, STOPPED, NO_MEDIA_PRESENT]
        """
        return 'STOPPED'

    def get_state_transport_status(self) -> str:
        """
        :return: string in [OK, ERROR_OCCURRED]
        """
        return 'OK'

    def get_state_speed(self) -> str:
        return '1'

    def get_state_display_subtitle(self) -> bool:
        return True


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

    def set_value(self, value):
        self.value = value

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


class Service:
    service_map = {}

    @classmethod
    def get(cls, name):
        return cls.service_map.get(name, Service(name))

    @classmethod
    def build(cls, name, ns, actions):
        cls.service_map[name] = Service(name, ns, actions)

    def __init__(self, name, namespace='', actions={}):
        self.name = name
        self.namespace = namespace
        self.actions = actions


class DLNAProtocol(Protocol):

    def __init__(self):
        super(DLNAProtocol, self).__init__()
        self.running = False
        self.state_list = {}
        self.action_list = {}
        self.event_thread = None
        self.event_subscribes = {}  # subscribe devices
        self.state_queue = Queue()  # states needed be send to subscribe devices
        self.removed_device_queue = Queue()  # devices needed be removed
        self.append_device_queue = Queue()  # devices needed be added
        self.init_services()  # create services handle function from xml file
        self.init_state()  # set default value

    @property
    def handler(self):
        if self._handler is None:
            self._handler = DLNAHandler()
        return self._handler

    def init_state(self):
        self.set_state('CurrentPlayMode', 'NORMAL')
        self.set_state('TransportPlaySpeed', 1)
        self.set_state('TransportStatus', 'OK')
        self.set_state('RelativeCounterPosition', 2147483647)
        self.set_state('AbsoluteCounterPosition', 2147483647)
        self.set_state('A_ARG_TYPE_Direction', 'Output')
        self.set_state('CurrentConnectionIDs', '0')
        self.set_state('PlaybackStorageMedium', 'None')
        self.set_state('SinkProtocolInfo', load_xml(XMLPath.PROTOCOL_INFO.value).strip())

    def init_services(self, description=XMLPath.DESCRIPTION.value):
        """
        :param description: dlna description xml file
        :return:
        """
        desc = etree.parse(description).getroot()
        for service_type in desc.iter('{urn:schemas-upnp-org:device-1-0}serviceType'):
            # service_type:  urn:schemas-upnp-org:service:ConnectionManager:1
            namespace = service_type.text
            service = service_type.text.split(":")[3]
            self.build_action(namespace, service, etree.parse(
                XMLPath.BASE_PATH.value + f"/xml/{service}.xml").getroot())

    def build_action(self, namespace, service, xml):
        """
        :param namespace: eg: urn:schemas-upnp-org:service:ConnectionManager:1
        :param service:  eg: ConnectionManager
        :param xml: xml content of service
        :return:
        """
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
            default_value = state_variable.find(ns + "defaultValue")
            if default_value is not None:
                data.set_value(default_value.text)
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
        # self.action_list[service] = actions
        Service.build(service, namespace, actions)

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
        threading.Thread(target=self.send_init_event,
                         kwargs={
                             'service': service,
                             'client': client
                         }).start()
        return {
            "SID": client.sid,
            "TIMEOUT": "Second-{}".format(client.timeout)
        }

    def send_init_event(self, service, client):
        """When there is a client subscription,
        the first event callback will send all the state values of the service.
        """
        data = {}
        for state in SERVICE_STATE_OBSERVED[service]:
            data[state] = self.state_list[state].value
        try:
            client.send_event_callback(data)
        except Exception as e:
            logger.error(str(e))

    def remove_subscribe(self, sid):
        """Remove a DLNA client from subscribe list
        """
        if sid in self.event_subscribes:
            self.removed_device_queue.put(sid)
        return 200

    def renew_subscribe(self, sid, timeout=1800):
        """Renew a DLNA client in subcribe list
        """
        if sid in self.event_subscribes:
            self.event_subscribes[sid].update(timeout)
            return 200
        return 412

    def send_states_to_clients(self, state_change_list):
        """Sending the states in the stateChangeList to the clients which subscribe to them.
        :param state_change_list:
        :return:
        """
        if not bool(state_change_list):
            return
        # remove offline clients
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
        """DLNA Event thread
        If a DLNA client subscribes to the dlna event,
        it will automatically send the event to the client when the renderer state changes.
        """
        while self.running:
            if not self.state_queue.empty():
                state = {}
                while not self.state_queue.empty():
                    k, v = self.state_queue.get()
                    state[k] = v
                    self.state_queue.task_done()
                self.send_states_to_clients(state)
            time.sleep(1)

    def call(self, rawbody):
        """Processing requests from DLNA clients
        The request from the client is passed into this method
        through the DLNAHandler(macast.py -> class DLNAHandler).
        If the Render class implements the corresponding action method,
        the method will be called automatically.
        Otherwise, the corresponding state variable will be returned
        according to the **action return value** described in the XML file.
        :param rawbody: soap request from dlna client
        :return:
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
        service_type = Service.get(service)
        if hasattr(self, method):
            data = {}
            # input = self.action_list[service][action].input
            input = service_type.actions[action].input
            for arg in input:
                data[arg.name] = Argument(
                    arg.name, arg.state,
                    param[arg.name] if arg.name in param else None)
                if arg.name in param:
                    self.set_state(arg.state, param[arg.name])
            res = getattr(self, method)(data)
        else:
            # output = self.action_list[service][action].output
            output = service_type.actions[action].output
            for arg in output:
                res[arg.name] = self.state_list[arg.state].value
        if method not in ['ConnectionManager_GetProtocolInfo', 'AVTransport_GetPositionInfo']:
            logger.info("{}res: {}".format("*" * 20, res))
        else:
            logger.info("{}res: {}".format("*" * 20, method))

        # build response xml
        ns = 'http://schemas.xmlsoap.org/soap/envelope/'
        encoding = 'http://schemas.xmlsoap.org/soap/encoding/'
        root = etree.Element(etree.QName(ns, 'Envelope'), nsmap={'s': ns})
        root.attrib[f'{{{ns}}}encodingStyle'] = encoding
        body = etree.SubElement(root, etree.QName(ns, 'Body'), nsmap={'s': ns})
        # namespace = 'urn:schemas-upnp-org:service:{}:1'.format(service)
        response = etree.SubElement(body,
                                    etree.QName(
                                        service_type.namespace, '{}Response'.format(action)),
                                    nsmap={'u': service_type.namespace})
        for key in res:
            prop = etree.SubElement(response, key)
            prop.text = str(res[key])
        return etree.tostring(root, encoding="UTF-8", xml_declaration=False)

    def set_state(self, name: str, value) -> None:
        """Set DLNA state which defined by xml file
        :param name: state name
        :param value: state value
        :return:
        """
        # update states which will send to DLNA Client
        if name in SERVICE_STATE_OBSERVED['AVTransport'] or \
                name in SERVICE_STATE_OBSERVED['RenderingControl']:
            logger.debug("setState: {} {}".format(name, value))
            # When some states change, the DLNA client needs to be notified immediately
            # We put this kind of state into state_queue, waiting to be sent to client.
            self.state_queue.put((name, value))
        # update other states
        if self.state_list[name].value != value:
            self.state_list[name].value = value

    def get_state(self, name: str):
        """Get DLNA state, The type of state is described by XML file
        :param name: DLNA state name
        :return: int/string/bool
        """
        return self.state_list[name].value

    def start(self):
        """Start render thread
        """
        if self.running:
            return

        self.running = True
        self.event_thread = threading.Thread(target=self.event, daemon=True)
        self.event_thread.start()
        self.set_state_stop()

    def stop(self):
        """Stop render thread
        """
        self.running = False

    # The following method names are defined by the XML file

    def RenderingControl_SetVolume(self, data):
        volume = data['DesiredVolume']
        self.renderer.set_media_volume(volume.value)
        return {}

    def RenderingControl_SetMute(self, data):
        mute = data['DesiredMute']
        if mute.value == 0 or mute.value == '0':
            mute = False
        else:
            mute = True
        self.renderer.set_media_mute(mute)
        return {}

    def AVTransport_SetAVTransportURI(self, data):
        uri = data['CurrentURI'].value
        logger.info(uri)
        self.set_state_url(uri)
        self.renderer.set_media_url(uri)
        title = Setting.get_friendly_name()
        try:
            meta = etree.fromstring(data['CurrentURIMetaData'].value.encode())
            title_xml = meta.find('.//{{{}}}title'.format(meta.nsmap['dc']))
            if title_xml is not None and title_xml.text is not None:
                title = title_xml.text
            metadata = etree.tostring(meta, encoding="UTF-8", xml_declaration=False)
        except Exception as e:
            logger.error(str(e))
            logger.error(data['CurrentURIMetaData'].value)
            self.set_state('CurrentTrackMetaData', data['CurrentURIMetaData'].value)
        else:
            self.set_state('CurrentTrackMetaData', metadata.decode())
        self.renderer.set_media_title(title)
        self.renderer.set_media_resume()
        self.set_state('CurrentTrackTitle', title)
        self.set_state('CurrentTrackURI', uri)
        self.set_state('RelativeTimePosition', '00:00:00')
        self.set_state('AbsoluteTimePosition', '00:00:00')
        self.set_state('TransportState', 'PAUSED_PLAYBACK')
        self.set_state('TransportStatus', 'OK')
        return {}

    def AVTransport_Play(self, data):
        self.renderer.set_media_resume()
        self.set_state('TransportState', 'PLAYING')
        self.set_state('TransportStatus', 'OK')
        return {}

    def AVTransport_Pause(self, data):
        self.renderer.set_media_pause()
        self.set_state('TransportState', 'PAUSED_PLAYBACK')
        return {}

    def AVTransport_Seek(self, data):
        target = data['Target']
        self.renderer.set_media_position(target.value)
        self.set_state('RelativeTimePosition', target.value)
        self.set_state('AbsoluteTimePosition', target.value)
        return {}

    def AVTransport_Stop(self, data):
        self.renderer.set_media_stop()
        self.set_state('TransportState', 'STOPPED')
        return {}

    # The following methods are usually used to update the states of
    # DLNA Renderer according to the status obtained from the player.
    # So, when your player state changes, call the following methods.
    # For example, when you click the pause button of the player,
    # call "self.protocol.set_state_pause()" from renderer
    # Then, the DLNA client (such as your mobile phone) will
    # automatically get this information and update it to the front-end.

    def set_state_position(self, data: str):
        """
        :param data: string, eg: 00:00:00
        :return:
        """
        self.set_state('RelativeTimePosition', data)
        self.set_state('AbsoluteTimePosition', data)

    def set_state_duration(self, data: str):
        """
        :param data: string, eg: 00:00:00
        :return:
        """
        self.set_state('CurrentTrackDuration', data)
        self.set_state('CurrentMediaDuration', data)

    def set_state_pause(self):
        self.set_state_transport('PAUSED_PLAYBACK')

    def set_state_play(self):
        self.set_state_transport('PLAYING')

    def set_state_stop(self):
        self.set_state_transport('STOPPED')

    def set_state_eof(self):
        self.set_state_transport('NO_MEDIA_PRESENT')

    def set_state_transport(self, data: str):
        """
        :param data: string in [PLAYING, PAUSED_PLAYBACK, STOPPED, NO_MEDIA_PRESENT]
        :return:
        """
        self.set_state('TransportState', data)
        self.set_state('TransportStatus', 'OK')

    def set_state_transport_error(self):
        """
        :return:
        """
        self.set_state('TransportState', 'STOPPED')
        self.set_state('TransportStatus', 'ERROR_OCCURRED')

    def set_state_mute(self, data: bool):
        """
        :param data: bool
        :return:
        """
        self.set_state('Mute', data)

    def set_state_volume(self, data: int):
        """
        :param data: int, range from 0 to 100
        :return:
        """
        self.set_state('Volume', data)

    def set_state_speed(self, data: str):
        self.set_state('TransportPlaySpeed', data)

    def set_state_display_subtitle(self, data: bool):
        self.set_state('DisplayCurrentSubtitle', data)

    def set_state_url(self, data: str):
        self.set_state('CurrentTrackURI', data)

    # When you are implementing another protocol similar to DLNA,
    # you can get the status of DLNA renderer by calling the following methods.
    # Using DLNA protocol usually does not need to pay attention to these methods,
    # because the state of renderer will be read automatically when using DLNA protocol.

    def get_state_title(self) -> str:
        """
        :return: string, eg: demo
        """
        return self.get_state('CurrentTrackTitle')

    def get_state_url(self) -> str:
        """
        :return: string, eg: http://10.10.10.10/demo.mp4
        """
        return self.get_state('CurrentTrackURI')

    def get_state_position(self) -> str:
        """
        :return: string, eg: 00:00:00
        """
        return self.get_state('RelativeTimePosition')

    def get_state_duration(self) -> str:
        """
        :return: string, eg: 00:00:00
        """
        return self.get_state('CurrentMediaDuration')

    def get_state_volume(self) -> int:
        """
        :return: int, range from 0 to 100
        """
        return self.get_state('Volume')

    def get_state_mute(self) -> bool:
        """
        :return: bool
        """
        return self.get_state('Mute')

    def get_state_transport_state(self) -> str:
        """
        :return: string in [PLAYING, PAUSED_PLAYBACK, STOPPED, NO_MEDIA_PRESENT]
        """
        return self.get_state('TransportState')

    def get_state_transport_status(self) -> str:
        """
        :return: string in [OK, ERROR_OCCURRED]
        """
        return self.get_state('TransportStatus')

    def get_state_speed(self) -> str:
        return self.get_state('TransportPlaySpeed')

    def get_state_display_subtitle(self) -> bool:
        return bool(self.get_state('DisplayCurrentSubtitle'))


@cherrypy.expose
class Handler:

    def __init__(self):
        self.setting_page = load_xml(XMLPath.SETTING_PAGE.value).encode()
        self.__downloading = False

    @property
    def protocol(self) -> Protocol:
        protocols = cherrypy.engine.publish('get_protocol')
        if len(protocols) == 0:
            logger.error("Unable to find an available protocol.")
            return Protocol()
        return protocols.pop()

    def reload(self):
        cherrypy.server.httpserver = _cpnative_server.CPHTTPServer(cherrypy.server)

    def __download_plugin(self, path, url):
        try:
            with open(path, 'wb') as f:
                f.write(requests.get(url).content)
        except Exception as e:
            logger.error(f"download plugin error: {e}")
        finally:
            self.__downloading = False
            Setting.restart()
            # cherrypy.engine.restart()

    def GET(self, param=None, *args, **kwargs):
        if not Setting.is_service_running():
            raise cherrypy.HTTPError(503, 'Server restarting')
        if param == 'api':
            cherrypy.response.headers['Content-Type'] = 'application/json;charset:utf-8'
            query = kwargs.get('query', '')
            res = {
                'api?query=log': 'get logs of macast',
                'api?query=settings': 'get settings of macast',
            }
            if query == 'log':
                log_path = os.path.join(SETTING_DIR, 'macast.log')
                data = ''
                try:
                    with open(log_path, 'r', encoding='utf-8') as f:
                        data = f.read()
                except:
                    pass
                res = {"logs": data}
            elif query == 'launch-param':
                res = Setting.setting
            elif query == 'plugin-info':
                info = cherrypy_publish('get_plugin_info', [])
                res = {
                    'platform': sys.platform,
                    'version': Setting.version,
                    'plugins': info
                }
            return json.dumps(res, indent=4).encode()
        if param is not None:
            raise cherrypy.HTTPRedirect('/')
        cherrypy.response.headers['Content-Type'] = 'text/html'
        # return self.setting_page
        return load_xml(XMLPath.SETTING_PAGE.value).encode()

    def POST(self, *args, **kwargs):
        cherrypy.response.headers['Content-Type'] = 'application/json;charset:utf-8'
        res = {'code': 0, 'message': 'success'}
        if kwargs.get('save-launch-param', None) is not None:
            setting = kwargs.get('save-launch-param', None)
            try:
                setting = json.loads(setting)
            except Exception as e:
                res['code'] = 1
                res['message'] = 'json format error'
            else:
                Setting.setting = setting
                Setting.save()
                Setting.restart()
                # cherrypy.engine.restart()
        elif kwargs.get('install-plugin', None) is not None:
            plugin = kwargs.get('install-plugin', None)
            if self.__downloading:
                cherrypy.engine.publish('app_notify', 'ERROR', 'Downloading other plugin now')
                res['code'] = 1
                res['message'] = 'Downloading other plugin now'
            else:
                cherrypy.engine.publish('app_notify', 'INFO', 'installing plugin...')
                self.__downloading = True
                try:
                    plugin = json.loads(plugin)
                    url = plugin.get('url', '')
                    plugin_name = url.split('/')[-1]
                    local_path = os.path.join(SETTING_DIR, plugin.get('type', 'renderer'), plugin_name)
                    threading.Thread(target=self.__download_plugin(local_path, url),
                                     daemon=True).start()
                except Exception as e:
                    res['code'] = 1
                    res['message'] = 'json format error'
        else:
            logger.info(kwargs)

        return json.dumps(res, indent=4).encode()


@cherrypy.expose
class DLNAHandler(Handler):
    """Receiving requests from DLNA client
    and communicating with the RenderPlugin thread
    see also: plugin.py -> class RenderPlugin
    """

    def __init__(self):
        super(DLNAHandler, self).__init__()
        self.description = None
        self.reload()

    def reload(self):
        super(DLNAHandler, self).reload()
        self.build_description()

    @property
    def protocol(self) -> DLNAProtocol:
        protocols = cherrypy.engine.publish('get_protocol')
        if len(protocols) == 0:
            logger.error("Unable to find an available protocol.")
            return DLNAProtocol()
        return protocols.pop()

    def build_description(self):
        self.description = load_xml(XMLPath.DESCRIPTION.value).format(
            friendly_name=Setting.get_friendly_name(),
            manufacturer="xfangfang",
            manufacturer_url="https://github.com/xfangfang",
            model_description="AVTransport Media Renderer",
            model_name="Macast",
            model_url="https://xfangfang.github.io/Macast",
            model_number=Setting.get_version(),
            uuid=Setting.get_usn(),
            serial_num=1024,
            header_extra="",
            service_extra=""
        ).encode()

    def GET(self, param=None, *args, **kwargs):
        if param == 'description.xml':
            return self.description
        return super(DLNAHandler, self).GET(param, *args, **kwargs)

    def POST(self, service=None, param=None, *args, **kwargs):
        length = cherrypy.request.headers['Content-Length']
        rawbody = cherrypy.request.body.read(int(length))
        logger.debug('RAW: {}'.format(rawbody))
        if param == 'action':
            res = self.protocol.call(rawbody)
            cherrypy.response.headers['EXT'] = ''
            logger.debug('RES: {}'.format(res))
            return res
        return super(DLNAHandler, self).POST(service, param, *args, **kwargs)

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
                res = self.protocol.renew_subscribe(SID, TIMEOUT)
                if res != 200:
                    logger.error("RENEW SUBSCRIBE: cannot find such sid.")
                    raise cherrypy.HTTPError(status=res)
                cherrypy.response.headers['SID'] = SID
                cherrypy.response.headers['TIMEOUT'] = TIMEOUT
            elif CALLBACK:
                logger.error("ADD SUBSCRIBE:!!!!!!!" + service)
                suburl = re.findall("<(.*?)>", CALLBACK)[0]
                res = self.protocol.add_subscribe(service, suburl, TIMEOUT)
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
                res = self.protocol.remove_subscribe(SID)
                if res != 200:
                    raise cherrypy.HTTPError(status=res)
                return b''
        logger.error("UNSUBSCRIBE: error 412.")
        raise cherrypy.HTTPError(status=412)
