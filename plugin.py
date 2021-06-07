# Copyright (c) 2021 by xfangfang. All Rights Reserved.

from cherrypy.process import plugins
import logging

from ssdp import SSDPServer
from mpv import MPVRender, Render
from utils import PORT, Setting

logger = logging.getLogger("PLUGIN")
logger.setLevel(logging.DEBUG)


class RenderPlugin(plugins.SimplePlugin):
    def __init__(self, bus):
        super(RenderPlugin, self).__init__(bus)
        logger.error('Initializing RenderPlugin')
        self.render = Render()

    def start(self):
        logger.error('starting RenderPlugin')
        self.render.start()
        self.bus.subscribe('call_render', self.render.call)
        self.bus.subscribe('add_subscribe', self.render.addSubcribe)
        self.bus.subscribe('renew_subscribe', self.render.renewSubcribe)
        self.bus.subscribe('remove_subscribe', self.render.removeSubcribe)

    def stop(self):
        logger.error('Stoping RenderPlugin')
        self.bus.unsubscribe('call_render', self.render.call)
        self.bus.unsubscribe('add_subscribe', self.render.addSubcribe)
        self.bus.unsubscribe('renew_subscribe', self.render.renewSubcribe)
        self.bus.unsubscribe('remove_subscribe', self.render.removeSubcribe)
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
            '::upnp:rootdevice',
            '',
            '::urn:schemas-upnp-org:device:MediaRenderer:1',
            '::urn:schemas-upnp-org:service:RenderingControl:1',
            '::urn:schemas-upnp-org:service:ConnectionManager:1',
            '::urn:schemas-upnp-org:service:AVTransport:1'
        ]
        logger.info('Initializing SSDPPlugin')

    def notify(self):
        for type in self.devices:
            self.ssdp.do_notify('uuid:{}{}'.format(Setting.getUSN(), type))

    def register(self):
        ip = Setting.getIP()
        for type in self.devices:
            self.ssdp.register('local',
                'uuid:{}{}'.format(Setting.getUSN(), type),
                type,
                'http://{}:{}/description.xml'.format(ip, PORT))

    def unregister(self):
        for type in self.devices:
            self.ssdp.unregister('uuid:{}{}'.format(Setting.getUSN(), type))

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
