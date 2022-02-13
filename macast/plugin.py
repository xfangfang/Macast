# Copyright (c) 2021 by xfangfang. All Rights Reserved.
#
# Cherrypy Plugins
# Cherrypy uses Plugin to run background thread
#
import threading
import cherrypy
import logging
from cherrypy.process import plugins

from .ssdp import SSDPServer

logger = logging.getLogger("PLUGIN")


class PriorityPlugin(plugins.SimplePlugin):
    """Add startup priority to CherryPy's SimplePlugin
    The main reason for adding this function is that when starting the software,
    you need to start service discovery services such as SSDP first,
    and then start Protocol and Renderer services.
    """

    def __init__(self, priority=50):
        super(PriorityPlugin, self).__init__(cherrypy.engine)
        self.priority = priority

    def subscribe(self):
        """Register this object as a (multi-channel) listener on the bus."""
        for channel in self.bus.listeners:
            # Subscribe self.start, self.exit, etc. if present.
            method = getattr(self, channel, None)
            if method is not None:
                self.bus.subscribe(channel, method, self.priority)


class RendererPlugin(PriorityPlugin):
    """Run a background player thread
    """

    def __init__(self, priority, renderer):
        logger.info('Initializing RenderPlugin')
        super(RendererPlugin, self).__init__(priority)
        self.renderer = renderer

    def start(self):
        """Start RenderPlugin
        """
        logger.info('Starting RenderPlugin')
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


class ProtocolPlugin(PriorityPlugin):
    """Run a background protocol thread
    """

    def __init__(self, priority, protocol):
        logger.info('Initializing ProtocolPlugin')
        super(ProtocolPlugin, self).__init__(priority)
        self.protocol = protocol

    def reload_protocol(self):
        """Reload protocol
        """
        self.protocol.stop()
        self.protocol.start()

    def start(self):
        """Start ProtocolPlugin
        """
        logger.info('Starting ProtocolPlugin')
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


class SSDPPlugin(PriorityPlugin):
    """Run a background SSDP thread
    """

    def __init__(self, bus):
        logger.info('Initializing SSDPPlugin')
        super(SSDPPlugin, self).__init__(bus)
        self.ssdp = SSDPServer()

    def register(self, devices, desc, server, cache):
        """register device
        """
        for device in devices:
            self.ssdp.register(device.get('usn', ''),
                               device.get('nt', ''),
                               desc,
                               server,
                               cache)

    def update_ip(self):
        """ restart ssdp thread to update ip
        """
        logger.info('SSDP Restart to update ip')
        self.ssdp.sending_byebye = False  # don't send bye bye
        self.ssdp.stop()
        self.ssdp.start()

    def start(self):
        """Start SSDPPlugin
        """
        logger.info('Starting SSDPPlugin')
        self.ssdp.start()
        self.bus.subscribe('get_ssdp_server', self.get_ssdp_server)
        self.bus.subscribe('update_ip', self.update_ip)
        self.bus.subscribe('ssdp_register', self.register)
        self.bus.subscribe('ssdp_unregister', self.ssdp.unregister_all)

    def stop(self):
        """Stop SSDPPlugin
        """
        logger.info('Stopping SSDPPlugin')
        self.bus.unsubscribe('get_ssdp_server', self.get_ssdp_server)
        self.bus.unsubscribe('update_ip', self.update_ip)
        self.bus.unsubscribe('ssdp_register', self.register)
        self.bus.unsubscribe('ssdp_unregister', self.ssdp.unregister_all)
        self.ssdp.stop()

    def get_ssdp_server(self):
        return self.ssdp


class ToolPlugin(PriorityPlugin):

    def __init__(self, bus, tools):
        logger.info('Initializing ToolPlugin')
        super(ToolPlugin, self).__init__(bus)
        self.tool_list = tools
        self.tool_list_lock = threading.Lock()
        self.running = False
        self.bus.subscribe('append_tool', self.append_tool)
        self.bus.subscribe('remove_tool', self.remove_tool)

    def start(self):
        logger.info("Starting ToolPlugin")
        self.running = True
        with self.tool_list_lock:
            for tool in self.tool_list:
                tool.start()

    def stop(self):
        logger.info('Stopping ToolPlugin')
        self.running = False
        with self.tool_list_lock:
            for tool in self.tool_list:
                tool.stop()

    def append_tool(self, tool):
        if self.running:
            tool.start()
        with self.tool_list_lock:
            self.tool_list.append(tool)

    def remove_tool(self, tool):
        if self.running:
            tool.stop()
        with self.tool_list_lock:
            self.tool_list.remove(tool)
