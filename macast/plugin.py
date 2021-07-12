# Copyright (c) 2021 by xfangfang. All Rights Reserved.
#
# Cherrypy Plugins
# Cherrypy uses Plugin to run background thread
#

from cherrypy.process import plugins
import logging

from .ssdp import SSDPServer
from .mpv import MPVRender, Render
from .utils import PORT, Setting

logger = logging.getLogger("PLUGIN")


class RenderPlugin(plugins.SimplePlugin):
    """Run a background player thread
    """
    def __init__(self, bus):
        logger.info('Initializing RenderPlugin')
        super(RenderPlugin, self).__init__(bus)
        self.render = Render()

    def reloadRender(self):
        """Reload Render
          In some cases, you need to adjust the player's parameters,
        then you need to call this method to reload player.
        """
        self.render.stop()
        self.render.start()

    def start(self):
        """Start RenderPlugin
        """
        logger.info('starting RenderPlugin')
        self.render.start()
        self.bus.subscribe('call_render', self.render.call)
        self.bus.subscribe('add_subscribe', self.render.addSubcribe)
        self.bus.subscribe('renew_subscribe', self.render.renewSubcribe)
        self.bus.subscribe('remove_subscribe', self.render.removeSubcribe)
        self.bus.subscribe('reloadRender', self.reloadRender)

    def stop(self):
        """Stop RenderPlugin
        """
        logger.info('Stoping RenderPlugin')
        self.bus.unsubscribe('call_render', self.render.call)
        self.bus.unsubscribe('add_subscribe', self.render.addSubcribe)
        self.bus.unsubscribe('renew_subscribe', self.render.renewSubcribe)
        self.bus.unsubscribe('remove_subscribe', self.render.removeSubcribe)
        self.bus.unsubscribe('reloadRender', self.reloadRender)
        self.render.stop()


class MPVPlugin(RenderPlugin):
    """Using MPV as render
    """
    def __init__(self, bus):
        super(MPVPlugin, self).__init__(bus)
        self.render = MPVRender()

    def reloadRender(self):
        """Reload MPV
        If the MPV is playing content before reloading the player,
        then continue playing the previous content after the reload
        """
        uri = self.render.getState('AVTransportURI')
        position = self.render.getState('AbsoluteTimePosition')

        def loadfile():
            logger.debug("mpv loadfile")
            self.render.sendCommand(['loadfile', uri, 'replace'])
            self.bus.unsubscribe('mpvipc_start', loadfile)

        if self.render.getState('TransportState') == 'PLAYING':
            self.bus.subscribe('mpvipc_start', loadfile)
        self.render.stop()
        self.render.start()


class SSDPPlugin(plugins.SimplePlugin):
    """Run a background SSDP thread
    """
    def __init__(self, bus):
        logger.info('Initializing SSDPPlugin')
        super(SSDPPlugin, self).__init__(bus)
        self.ssdp = SSDPServer()
        self.devices = [
            'uuid:{}::upnp:rootdevice'.format(Setting.getUSN()),
            'uuid:{}'.format(Setting.getUSN()),
            'uuid:{}::urn:schemas-upnp-org:device:MediaRenderer:1'.format(
                Setting.getUSN()),
            'uuid:{}::urn:schemas-upnp-org:service:RenderingControl:1'.format(
                Setting.getUSN()),
            'uuid:{}::urn:schemas-upnp-org:service:ConnectionManager:1'.format(
                Setting.getUSN()),
            'uuid:{}::urn:schemas-upnp-org:service:AVTransport:1'.format(
                Setting.getUSN())
        ]

    def notify(self):
        """ssdp do notify
        """
        for device in self.devices:
            self.ssdp.do_notify(device)

    def register(self):
        """register device
        """
        ip = Setting.getIP()
        for device in self.devices:
            self.ssdp.register('local', device,
                               device[43:] if device[43:] != '' else device,
                               'http://{}:{}/description.xml'.format(ip, PORT))

    def unregister(self):
        """unregister device
        """
        for device in self.devices:
            self.ssdp.unregister(device)

    def updateIP(self):
        """Update the device ip address
        """
        self.unregister()
        self.register()

    def start(self):
        """Start SSDPPlugin
        """
        logger.info('starting SSDPPlugin')
        self.register()
        self.ssdp.start()
        self.bus.subscribe('ssdp_notify', self.notify)
        self.bus.subscribe('ssdp_updateip', self.updateIP)

    def stop(self):
        """Stop SSDPPlugin
        """
        logger.info('Stoping SSDPPlugin')
        self.bus.unsubscribe('ssdp_notify', self.notify)
        self.bus.unsubscribe('ssdp_updateip', self.updateIP)
        self.ssdp.stop()
