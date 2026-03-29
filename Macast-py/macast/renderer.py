# Copyright (c) 2021 by xfangfang. All Rights Reserved.

import gettext
import logging
import cherrypy

from .protocol import Protocol

logger = logging.getLogger("Renderer")
logger.setLevel(logging.INFO)


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
        self.running = False
        self.renderer_setting = RendererSetting()

    def start(self):
        """Start render thread
        """
        self.running = True

    def stop(self):
        """Stop render thread
        """
        self.running = False
        cherrypy.engine.publish('renderer_av_stop')

    def reload(self):
        self.stop()
        self.start()

    def methods(self):
        return list(filter(lambda m: m.startswith('set_media_') and callable(getattr(self, m)), dir(self)))

    @property
    def protocol(self) -> Protocol:
        protocols = cherrypy.engine.publish('get_protocol')
        if len(protocols) == 0:
            logger.error("Unable to find an available protocol.")
            return Protocol()
        return protocols.pop()

    # If you want to write a new renderer adapted to another video player,
    # please rewrite the following methods to control the video player you use.
    # For details, please refer to macast_renderer/mpv.py:MPVRender

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

    def set_media_url(self, url: str, start: str = "0"):
        """
        :param url:
        :param start: relative time
            --start=+56, --start=00:56
            Seeks to the start time + 56 seconds.
            --start=-56, --start=-00:56
            Seeks to the end time - 56 seconds.
            --start=01:10:00
            Seeks to 1 hour 10 min.
            --start=50%
            Seeks to the middle of the file.
            --start=30
            Seeks to 30 seconds
        :return:
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

    def set_media_sub_file(self, data):
        """ set subtitle file path
        :param data: {'url': '/home/ubuntu/danmaku.ass',
                      'title': 'danmaku'}
        :return:
        """
        pass

    def set_media_sub_show(self, data: bool):
        """ set subtitle visibility
        :param data:
        :return:
        """
        pass

    def set_media_text(self, data: str, duration: int = 1000):
        """ show text on video player screen
        :param data: string, text content
        :param duration: ms
        :return:
        """
        pass

    def set_media_speed(self, data: float):
        pass

    # The following methods are usually used to update the states of
    # DLNA Renderer according to the status obtained from the player.
    # So, when your player state changes, call the following methods.
    # For example, when you click the pause button of the player,
    # call self.set_state('TransportState', 'PAUSED_PLAYBACK')
    # Then, the DLNA client (such as your mobile phone) will
    # automatically get this information and update it to the front-end.

    def set_state_position(self, data: str):
        """
        :param data: string, eg: 00:00:00
        :return:
        """
        self.protocol.set_state_position(data)

    def set_state_duration(self, data: str):
        """
        :param data: string, eg: 00:00:00
        :return:
        """
        self.protocol.set_state_duration(data)

    def set_state_pause(self):
        self.protocol.set_state_pause()

    def set_state_play(self):
        self.protocol.set_state_play()

    def set_state_stop(self):
        self.protocol.set_state_stop()

    def set_state_eof(self):
        self.protocol.set_state_eof()

    def set_state_transport(self, data: str):
        """
        :param data: string in [PLAYING, PAUSED_PLAYBACK, STOPPED, NO_MEDIA_PRESENT]
        :return:
        """
        self.protocol.set_state_transport(data)

    def set_state_transport_error(self):
        """
        :return:
        """
        self.protocol.set_state_transport_error()

    def set_state_mute(self, data: bool):
        """
        :param data: bool
        :return:
        """
        self.protocol.set_state_mute(data)

    def set_state_volume(self, data: int):
        """
        :param data: int, range from 0 to 100
        :return:
        """
        self.protocol.set_state_volume(data)

    def set_state_speed(self, data: str):
        self.protocol.set_state_speed(data)

    def set_state_subtitle(self, data: bool):
        self.protocol.set_state_display_subtitle(data)

    def set_state_url(self, data: str):
        self.protocol.set_state_url(data)

    def set_state(self, state_name, state_value):
        self.protocol.set_state(state_name, state_value)

    def get_state(self, state_name):
        return self.protocol.get_state(state_name)


class RendererSetting:
    """ Dummy menu settings class
    """

    def build_menu(self):
        return []
