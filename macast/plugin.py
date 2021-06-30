# Copyright (c) 2021 by xfangfang. All Rights Reserved.

from cherrypy.process import plugins
import logging

from .ssdp import SSDPServer
from .mpv import MPVRender, Render
from .utils import PORT, Setting

logger = logging.getLogger("PLUGIN")
logger.setLevel(logging.DEBUG)


class RenderPlugin(plugins.SimplePlugin):
    def __init__(self, bus):
        super(RenderPlugin, self).__init__(bus)
        logger.error('Initializing RenderPlugin')
        self.render = Render()

    def reloadRender(self):
        uri = self.render.getState('AVTransportURI')
        position = self.render.getState('AbsoluteTimePosition')

        def seek(duration):
            logger.debug("seek")
            self.render.sendCommand(['seek', position, 'absolute'])
            self.bus.unsubscribe('mpv_update_duration', seek)

        def loadfile():
            logger.debug("loadfile")
            self.render.sendCommand(['loadfile', uri, 'replace'])
            self.bus.unsubscribe('mpvipc_start', loadfile)
            self.bus.subscribe('mpv_update_duration', seek)

        if self.render.getState('TransportState') == 'PLAYING':
            self.bus.subscribe('mpvipc_start', loadfile)
        self.render.stop()
        self.render.start()

    def start(self):
        logger.error('starting RenderPlugin')
        self.render.start()
        self.bus.subscribe('call_render', self.render.call)
        self.bus.subscribe('add_subscribe', self.render.addSubcribe)
        self.bus.subscribe('renew_subscribe', self.render.renewSubcribe)
        self.bus.subscribe('remove_subscribe', self.render.removeSubcribe)
        self.bus.subscribe('reloadRender', self.reloadRender)

    def stop(self):
        logger.error('Stoping RenderPlugin')
        self.bus.unsubscribe('call_render', self.render.call)
        self.bus.unsubscribe('add_subscribe', self.render.addSubcribe)
        self.bus.unsubscribe('renew_subscribe', self.render.renewSubcribe)
        self.bus.unsubscribe('remove_subscribe', self.render.removeSubcribe)
        self.bus.unsubscribe('reloadRender', self.reloadRender)
        self.render.stop()

class MPVPlugin(RenderPlugin):
    def __init__(self, bus):
        super(MPVPlugin, self).__init__(bus)
        self.render = MPVRender()

class SSDPPlugin(plugins.SimplePlugin):
    def __init__(self, bus):
        super(SSDPPlugin, self).__init__(bus)
        self.ssdp = SSDPServer()
        self.devices = [
            'uuid:{}::upnp:rootdevice'.format(Setting.getUSN()),
            'uuid:{}'.format(Setting.getUSN()),
            'uuid:{}::urn:schemas-upnp-org:device:MediaRenderer:1'.format(Setting.getUSN()),
            'uuid:{}::urn:schemas-upnp-org:service:RenderingControl:1'.format(Setting.getUSN()),
            'uuid:{}::urn:schemas-upnp-org:service:ConnectionManager:1'.format(Setting.getUSN()),
            'uuid:{}::urn:schemas-upnp-org:service:AVTransport:1'.format(Setting.getUSN())
        ]
        logger.info('Initializing SSDPPlugin')

    def notify(self):
        for device in self.devices:
            self.ssdp.do_notify(device)

    def register(self):
        ip = Setting.getIP()
        for device in self.devices:
            self.ssdp.register('local',
                device,
                device[43:],
                'http://{}:{}/description.xml'.format(ip, PORT))

    def unregister(self):
        for device in self.devices:
            self.ssdp.unregister(device)

    def updateIP(self):
        self.unregister()
        self.register()

    def start(self):
        logger.info('starting SSDPPlugin')
        self.register()
        self.ssdp.start()
        self.bus.subscribe('ssdp_notify', self.notify)
        self.bus.subscribe('ssdp_updateip', self.updateIP)

    def stop(self):
        logger.info('Stoping SSDPPlugin')
        self.bus.unsubscribe('ssdp_notify', self.notify)
        self.bus.unsubscribe('ssdp_updateip', self.updateIP)
        self.ssdp.stop()
