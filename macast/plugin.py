# Copyright (c) 2021 by xfangfang. All Rights Reserved.
#
# Cherrypy Plugins
# Cherrypy uses Plugin to run background thread
#

from cherrypy.process import plugins
import logging

from .ssdp import SSDPServer
from .utils import Setting

logger = logging.getLogger("PLUGIN")


class RendererPlugin(plugins.SimplePlugin):
    """Run a background player thread
    """

    def __init__(self, bus, render):
        logger.info('Initializing RenderPlugin')
        super(RendererPlugin, self).__init__(bus)
        self.render = render

    def reload_render(self):
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
        self.bus.subscribe('add_subscribe', self.render.add_subscribe)
        self.bus.subscribe('renew_subscribe', self.render.renew_subcribe)
        self.bus.subscribe('remove_subscribe', self.render.remove_subscribe)
        self.bus.subscribe('reloadRender', self.render.reload)

    def stop(self):
        """Stop RenderPlugin
        """
        logger.info('Stoping RenderPlugin')
        self.bus.unsubscribe('call_render', self.render.call)
        self.bus.unsubscribe('add_subscribe', self.render.add_subscribe)
        self.bus.unsubscribe('renew_subscribe', self.render.renew_subcribe)
        self.bus.unsubscribe('remove_subscribe', self.render.remove_subscribe)
        self.bus.unsubscribe('reloadRender', self.render.reload)
        self.render.stop()


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
        for device in self.devices:
            self.ssdp.register(device,
                               device[43:] if device[43:] != '' else device,
                               'http://{{}}:{}/description.xml'.format(Setting.get_port()),
                               Setting.get_server_info(),
                               'max-age=66')

    def unregister(self):
        """unregister device
        """
        for device in self.devices:
            self.ssdp.unregister(device)

    def update_ip(self):
        """Update the device ip address
        """
        self.stop()
        self.start()

    def start(self):
        """Start SSDPPlugin
        """
        logger.info('starting SSDPPlugin')
        self.register()
        self.ssdp.start()
        self.bus.subscribe('ssdp_notify', self.notify)
        self.bus.subscribe('ssdp_update_ip', self.update_ip)

    def stop(self):
        """Stop SSDPPlugin
        """
        logger.info('Stoping SSDPPlugin')
        self.bus.unsubscribe('ssdp_notify', self.notify)
        self.bus.unsubscribe('ssdp_update_ip', self.update_ip)
        self.ssdp.stop()
