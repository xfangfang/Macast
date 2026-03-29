# Copyright (c) 2021 by xfangfang. All Rights Reserved.
#
# Cherrypy Plugins
# Cherrypy uses Plugin to run background thread
#

from cherrypy.process import plugins
import logging
import threading

from .ssdp import SSDPServer
from .utils import Setting

logger = logging.getLogger("PLUGIN")


class RendererPlugin(plugins.SimplePlugin):
    """Run a background player thread
    """

    def __init__(self, bus, renderer):
        logger.info('Initializing RenderPlugin')
        super(RendererPlugin, self).__init__(bus)
        self.renderer = renderer

    def start(self):
        """Start RenderPlugin
        """
        logger.info('starting RenderPlugin')
        self.renderer.start()
        self.bus.subscribe('reload_renderer', self.renderer.reload)
        self.bus.subscribe('get_renderer', self.get_renderer)
        self.bus.subscribe('set_renderer', self.set_renderer)
        for method in self.renderer.methods():
            self.bus.subscribe(method, getattr(self.renderer, method))

    def stop(self):
        """Stop RenderPlugin
        """
        logger.info('Stopping RenderPlugin')
        self.bus.unsubscribe('reload_renderer', self.renderer.reload)
        self.bus.unsubscribe('get_renderer', self.get_renderer)
        self.bus.unsubscribe('set_renderer', self.set_renderer)
        for method in self.renderer.methods():
            self.bus.unsubscribe(method, getattr(self.renderer, method))
        self.renderer.stop()

    def get_renderer(self):
        return self.renderer

    def set_renderer(self, renderer):
        self.stop()
        self.renderer = renderer
        self.start()


class ProtocolPlugin(plugins.SimplePlugin):
    """Run a background protocol thread
    """

    def __init__(self, bus, protocol):
        logger.info('Initializing ProtocolPlugin')
        super(ProtocolPlugin, self).__init__(bus)
        self.protocol = protocol

    def reload_protocol(self):
        """Reload protocol
        """
        self.protocol.stop()
        self.protocol.start()

    def start(self):
        """Start ProtocolPlugin
        """
        logger.info('starting ProtocolPlugin')
        self.protocol.start()
        self.bus.subscribe('reload_protocol', self.protocol.reload)
        self.bus.subscribe('get_protocol', self.get_protocol)
        self.bus.subscribe('set_protocol', self.set_protocol)
        for method in self.protocol.methods():
            self.bus.subscribe(method, getattr(self.protocol, method))

    def stop(self):
        """Stop ProtocolPlugin
        """
        logger.info('Stopping ProtocolPlugin')
        self.bus.unsubscribe('reload_protocol', self.protocol.reload)
        self.bus.unsubscribe('get_protocol', self.get_protocol)
        self.bus.unsubscribe('set_protocol', self.set_protocol)
        for method in self.protocol.methods():
            self.bus.unsubscribe(method, getattr(self.protocol, method))
        self.protocol.stop()

    def get_protocol(self):
        return self.protocol

    def set_protocol(self, protocol):
        self.stop()
        self.protocol = protocol
        self.start()


class SSDPPlugin(plugins.SimplePlugin):
    """Run a background SSDP thread
    """

    def __init__(self, bus):
        logger.info('Initializing SSDPPlugin')
        super(SSDPPlugin, self).__init__(bus)
        self.restart_lock = threading.Lock()
        self.ssdp = SSDPServer()
        self.devices = []
        self.build_device_info()

    def build_device_info(self):
        self.devices = [
            'uuid:{}::upnp:rootdevice'.format(Setting.get_usn()),
            'uuid:{}'.format(Setting.get_usn()),
            'uuid:{}::urn:schemas-upnp-org:device:MediaRenderer:1'.format(
                Setting.get_usn()),
            'uuid:{}::urn:schemas-upnp-org:service:RenderingControl:1'.format(
                Setting.get_usn()),
            'uuid:{}::urn:schemas-upnp-org:service:ConnectionManager:1'.format(
                Setting.get_usn()),
            'uuid:{}::urn:schemas-upnp-org:service:AVTransport:1'.format(
                Setting.get_usn())
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
        with self.restart_lock:
            self.ssdp.stop(byebye=False)
            self.build_device_info()
            self.register()
            self.ssdp.start()

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
        with self.restart_lock:
            self.ssdp.stop(byebye=True)
