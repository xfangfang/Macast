# Copyright (c) 2021 by xfangfang. All Rights Reserved.
#
# MPV Renderer and gui Setting
#

import os
import sys
import json
import time
import socket
import random
import subprocess
import logging
import threading
import cherrypy
import gettext
from enum import Enum

from macast.utils import Setting
from macast.renderer import Renderer, RendererSetting
from macast.gui import App, MenuItem

if os.name == 'nt':
    import _winapi
    from multiprocessing.connection import PipeConnection

logger = logging.getLogger("MPVRenderer")
# DEBUG, not INFO. The send_command() trace and update_state() payloads are the
# only record of what actually reached mpv; at INFO they were dropped by this
# logger's own level filter and never reached the file, which made "the command
# was never sent" look indistinguishable from "the command was sent and mpv
# ignored it". The root handler still decides what is finally written.
logger.setLevel(logging.DEBUG)


class ObserveProperty(Enum):
    volume = 1
    time_pos = 2
    pause = 3
    mute = 4
    duration = 5
    track_list = 6
    speed = 7
    sub = 8


class MPVRenderer(Renderer):
    """
      When the DLNA client accesses, MPVRenderer will returns the state value
    corresponding to "out" section in the action specified in the service XML
    file by default.
      When some "service_action" methods are implemented
    (such as "RenderingControl_SetVolume"), the DLNA client's access will be
    automatically directed to these methods
    """

    def __init__(self, lang=gettext.gettext, path="mpv"):
        super(MPVRenderer, self).__init__(lang)
        global _
        _ = lang
        mpv_rand = random.randint(0, 9999)
        if os.name == 'nt':
            self.mpv_sock = Setting.get_base_path(r"\\.\pipe\macast_mpvsocket{}".format(mpv_rand))
        else:
            self.mpv_sock = '/tmp/macast_mpvsocket{}'.format(mpv_rand)
        self.path = path
        self.proc = None
        self.title = Setting.get_friendly_name()
        self.mpv_thread = None
        self.ipc_thread = None
        self.ipc_sock = None
        self.pause = False  # changed with pause action
        self.playing = False  # changed with start and stop
        self.ipc_running = False
        self.ipc_once_connected = False
        # As long as IPC has been connected, the ipc_once_connected is True
        # When the ipc_once_connected is True, it shows that there is no error
        # in the starting parameters of MPV, and there is no need to wait for
        # one second to restart MPV.
        self.command_lock = threading.Lock()
        self.renderer_setting = MPVRendererSetting()

    def set_media_stop(self):
        self.send_command(['stop'])

    def set_media_pause(self):
        self.send_command(['set_property', 'pause', True])
        self.set_media_text('Pause')

    def set_media_resume(self):
        self.send_command(['set_property', 'pause', False])
        self.set_media_text('Resume')

    def set_media_volume(self, data):
        """ data : int, range from 0 to 100
        """
        self.send_command(['set_property', 'volume', data])
        self.set_media_text(f'Volume: {data}')

    def set_media_mute(self, data):
        """ data : bool
        """
        self.send_command(['set_property', 'mute', "yes" if data else "no"])
        self.set_media_text(f'Mute: {data}')

    def set_media_url(self, url, start="0"):
        """ data : string
        """
        logger.info('set_media_url: %s', url)
        try:
            options = {}
            # "start" is a loadfile option and mpv parses it as a position, so
            # it has to go over the wire as a number. Passing the string "0"
            # made mpv reject the whole command:
            #
            #   [ipc_0] The loadfile option must be an integer: start=0
            #   [ipc_0] Command loadfile: argument index can't be parsed
            #
            # loadfile answers "success" to a command it then refuses to run,
            # so nothing played and nothing complained. Normalise to a float
            # (that is what mpv's position parser accepts, and it also covers
            # callers that pass a "00:01:30" style position later on).
            try:
                options['start'] = float(start)
            except (TypeError, ValueError):
                options['start'] = 0.0
            player_size = Setting.get(SettingProperty.PlayerSize,
                                      default=SettingProperty.PlayerSize_Normal.value)
            if player_size == SettingProperty.PlayerSize_FullScreen.value:
                options['fullscreen'] = 'yes'
            # The index argument is mandatory once any option is passed:
            # loadfile's signature is
            #     loadfile <url> [flags] [index] [options]
            # so sending the options string in third place makes mpv parse it
            # as the index and refuse the whole command:
            #     [ipc_0] The loadfile option must be an integer: start=0.0
            #     [ipc_0] Command loadfile: argument index can't be parsed
            # -1 means "append to the end of the playlist", which is what we
            # want along with the "replace" flag.
            sent = self.send_command(['loadfile', url, 'replace', -1,
                                      ','.join([f'{i}={options[i]}' for i in options])])
            if not sent:
                logger.error('set_media_url: loadfile was not delivered to mpv')
            else:
                # Confirm the file actually opened. loadfile only queues the
                # request, so a stream the CDN refuses (403 on an expired
                # signed URL is routine -- DLNA clients hand out time-limited
                # URLs and the phone happily plays it seconds before it lapses)
                # is accepted, answered with "success", and then never plays.
                # The client is told PLAYING either way, so without this check
                # that failure is completely invisible.
                #
                # Runs off-thread: this poll waits up to 10s, and we are being
                # called from inside the SOAP handler, which is synchronous with
                # the DLNA client.
                threading.Thread(target=self.verify_playback_started, args=(url,),
                                 name='MPV_VERIFY').start()
        except Exception:
            # A client gets a 200 from SetAVTransportURI regardless, and the
            # player just sits idle with no window, so a failure here has to
            # say so loudly rather than vanish into CherryPy's handler.
            logger.exception('set_media_url failed')
            raise

    def verify_playback_started(self, url):
        """After loadfile, wait briefly and report if nothing is playing.

        mpv reports idle-active=true while it holds an empty playlist and also
        right after a load that failed to open, so poll until it either starts
        playing or we give up.
        """
        for _ in range(10):
            time.sleep(1)
            state = self.query_state()
            if state is None:
                continue
            if not state.get('idle-active', True):
                logger.info('set_media_url: playback started')
                return True
        logger.error('set_media_url: mpv stayed idle for 10s after loadfile, '
                     'the stream did not open. Check the "mpv:" lines above for '
                     'the reason (an HTTP 403 or 404 here usually means the '
                     'client handed out an expired or wrong-signed URL): %s',
                     url)
        # Tell the user, not just the log. This is the difference between a
        # player that is broken and a player that is being fed a dead link, and
        # from the phone they look identical -- the client reports PLAYING
        # either way.
        try:
            cherrypy.engine.publish('app_notify', 'Macast', _('Cannot play this media'))
        except Exception:
            pass
        return False

    def query_state(self):
        """Ask mpv for the properties that tell us whether it is playing.

        Runs on its own short-lived connection. The long-lived ipc_sock is
        serviced by start_ipc's receive loop, which would consume our reply
        before update_state ever saw it, so it cannot be shared.
        """
        import socket as _socket
        if self.ipc_sock is None:
            return None
        if os.name == 'nt':
            return None
        sock = None
        try:
            sock = _socket.socket(_socket.AF_UNIX, _socket.SOCK_STREAM)
            sock.settimeout(3)
            sock.connect(self.mpv_sock)
            sock.sendall((json.dumps({
                'command': ['get_property', 'idle-active']}) + '\n').encode())
            deadline = time.time() + 3
            buf = b''
            while time.time() < deadline:
                try:
                    chunk = sock.recv(4096)
                except _socket.timeout:
                    break
                if not chunk:
                    break
                buf += chunk
                for line in buf.decode('utf-8', 'replace').split('\n'):
                    if not line.strip():
                        continue
                    try:
                        msg = json.loads(line)
                    except ValueError:
                        continue
                    if 'error' in msg:
                        if msg.get('error') == 'success' and 'data' in msg:
                            return {'idle-active': msg['data']}
                        return None
            return None
        except Exception as e:
            logger.debug('query_state failed: %s', e)
            return None
        finally:
            if sock is not None:
                try:
                    sock.close()
                except Exception:
                    pass

    def set_media_title(self, data):
        """ data : string
        """
        self.title = data
        self.send_command(['set_property', 'title', data])

    def set_media_position(self, data):
        """ data : position, 00:00:00
        """
        self.send_command(['seek', data, 'absolute'])

    def set_media_sub_file(self, data):
        self.send_command(['sub-add', data['url'], 'select', data['title']])

    def set_media_sub_show(self, data: bool):
        self.send_command(['set_property', 'sub-visibility', "yes" if data else "no"])

    def set_media_text(self, data: str, duration: int = 1000):
        self.send_command(['show-text', data, duration])

    def set_media_speed(self, data: float = 1):
        """
        :param data: range(0.01 - 100)
        :return:
        """
        self.send_command(['set_property', 'speed', data])

    def set_observe(self):
        """Set several property that needed observe
        """
        self.send_command(
            ['observe_property', ObserveProperty.volume.value, 'volume'])
        self.send_command(
            ['observe_property', ObserveProperty.time_pos.value, 'time-pos'])
        self.send_command(
            ['observe_property', ObserveProperty.pause.value, 'pause'])
        self.send_command(
            ['observe_property', ObserveProperty.mute.value, 'mute'])
        self.send_command(
            ['observe_property', ObserveProperty.duration.value, 'duration'])
        self.send_command(
            ['observe_property', ObserveProperty.track_list.value,
             'track-list'])
        self.send_command(
            ['observe_property', ObserveProperty.speed.value,
             'speed'])
        self.send_command(
            ['observe_property', ObserveProperty.sub.value,
             'sub-visibility'])

        self.set_media_volume(Setting.get(SettingProperty.PlayerDefaultVolume, 100))

    def update_state(self, res):
        """Update player state from mpv
        """
        res = json.loads(res)
        if 'id' in res:
            if res['id'] == ObserveProperty.volume.value:
                logger.debug(res)
                if 'data' in res and res['data'] is not None:
                    self.set_state_volume(int(res['data']))
            elif res['id'] == ObserveProperty.time_pos.value:
                if 'data' not in res or res['data'] is None:
                    position = '00:00:00'
                else:
                    sec = int(res['data'])
                    position = '%d:%02d:%02d' % (sec // 3600, (sec % 3600) // 60, sec % 60)
                self.set_state_position(position)
            elif res['id'] == ObserveProperty.pause.value:
                logger.debug(res)
                if self.playing is False:
                    return
                if res['data'] and res['data'] is not None:
                    self.pause = True
                    self.set_state_pause()
                else:
                    self.pause = False
                    self.set_state_play()
            elif res['id'] == ObserveProperty.mute.value:
                self.set_state_mute(res['data'])
            elif res['id'] == ObserveProperty.duration.value:
                if 'data' not in res or res['data'] is None:
                    duration = '00:00:00'
                else:
                    sec = int(res['data'])
                    duration = '%d:%02d:%02d' % (sec // 3600, (sec % 3600) // 60, sec % 60)
                    cherrypy.engine.publish('mpv_update_duration', duration)
                    logger.info("update duration " + duration)
                    if self.protocol.get_state_transport_state() == 'PLAYING':
                        logger.debug("Living media")
                self.set_state_duration(duration)
            elif res['id'] == ObserveProperty.track_list.value:
                if res['data'] and res['data'] is not None:
                    tracks = len(res['data'])
                    self.set_state('CurrentTrack', 0 if tracks == 0 else 1)
                    self.set_state('NumberOfTracks', tracks)
            elif res['id'] == ObserveProperty.speed.value:
                data = res.get('data', None)
                if data is not None:
                    self.set_state_speed(data)
            elif res['id'] == ObserveProperty.sub.value:
                data = res.get('data', None)
                if data is not None:
                    self.set_state_subtitle(data)
        elif 'event' in res:
            logger.debug(res)
            if res['event'] == 'end-file':
                cherrypy.engine.publish('renderer_av_stop')
                self.playing = False
                if 'reason' not in res:
                    self.set_state_stop()
                elif res['reason'] == 'error':
                    self.set_state_transport_error()
                elif res['reason'] == 'eof':
                    # NO_MEDIA_PRESENT
                    self.set_state_eof()
                else:
                    self.set_state_stop()
                if res.get('file_error', False):
                    cherrypy.engine.publish('app_notify',
                                            "File error",
                                            res['file_error'])
            elif res['event'] == 'start-file':
                self.playing = True
                # self.set_state_transport('TRANSITIONING')
                cherrypy.engine.publish('renderer_av_uri', self.protocol.get_state_url())
            elif res['event'] == 'seek':
                pass
                # self.set_state_transport('TRANSITIONING')
            elif res['event'] == 'idle':
                # video comes to end
                self.playing = False
                self.set_state_stop()
            elif res['event'] == 'playback-restart':
                # video is ready to play
                if self.pause:
                    self.set_state_pause()
                else:
                    self.set_state_play()
        else:
            logger.debug(res)

    def send_command(self, command):
        """Sending command to mpv
        """
        # Log the verb, not the whole argument list: loadfile carries the media
        # URL, and signed CDN links run to several hundred characters, which
        # would bury everything else in the log.
        logger.debug("send command: %s%s", command[0],
                     ' (%d args)' % (len(command) - 1) if len(command) > 1 else '')
        if self.ipc_sock is None:
            logger.error("sendCommand: ipc socket is not connected, dropping %s",
                         str(command))
            return False
        data = {"command": command}
        msg = json.dumps(data) + '\n'
        with self.command_lock:
            try:
                if os.name == 'nt':
                    self.ipc_sock.send_bytes(msg.encode())
                else:
                    self.ipc_sock.sendall(msg.encode())
                return True
            except Exception as e:
                logger.error('sendCommand: ' + str(e))
                return False

    def start_ipc(self):
        """Start ipc thread
        Communicating with mpv
        """
        if self.ipc_running:
            logger.error("mpv ipc is already runing")
            return
        self.ipc_running = True
        while self.ipc_running and self.running and self.mpv_thread.is_alive():
            try:
                time.sleep(0.5)
                logger.error("mpv ipc socket start connect")
                if os.name == 'nt':
                    handler = _winapi.CreateFile(
                        self.mpv_sock,
                        _winapi.GENERIC_READ | _winapi.GENERIC_WRITE, 0,
                        _winapi.NULL, _winapi.OPEN_EXISTING,
                        _winapi.FILE_FLAG_OVERLAPPED, _winapi.NULL)
                    self.ipc_sock = PipeConnection(handler)
                else:
                    self.ipc_sock = socket.socket(socket.AF_UNIX,
                                                  socket.SOCK_STREAM)
                    self.ipc_sock.connect(self.mpv_sock)
                cherrypy.engine.publish('mpvipc_start')
                cherrypy.engine.publish('renderer_start')
                self.ipc_once_connected = True
                self.set_observe()
            except Exception as e:
                logger.error("mpv ipc socket reconnecting: {}".format(str(e)))
                continue
            res = b''
            msgs = None
            while self.ipc_running:
                try:
                    if os.name == 'nt':
                        data = self.ipc_sock.recv_bytes(1048576)
                    else:
                        data = self.ipc_sock.recv(1048576)
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
                        self.update_state(msg)
                except Exception as e:
                    logger.error("decode error: {}".format(e))
                    logger.error(f"decode error data: {msg}")
                    logger.error(f"decode error data list: {msgs}")
                finally:
                    res = b''
            # ipc_sock stays referenced after close() until the loop reconnects
            # and replaces it. In that window a SetAVTransportURI from a DLNA
            # client writes to a closed socket, the exception is swallowed, and
            # the client still gets a 200 -- so the media silently never reaches
            # the player. Clearing it makes send_command() refuse loudly instead.
            try:
                self.ipc_sock.close()
            except Exception:
                pass
            self.ipc_sock = None
            logger.error("mpv ipc stopped")

    def drain_mpv_output(self):
        """Copy mpv's terminal output into our log until mpv exits.

        This replaces the blocking proc.communicate() that used to sit here.
        communicate() only returns once mpv exits, so for the whole life of the
        player nothing was read from the pipe, and mpv's status line alone
        ("AV: 00:00:00 / 00:06:39 ...") would have been enough to fill the
        64 KB pipe buffer and wedge mpv's own writes.
        """
        stream = self.proc.stdout
        if stream is None:
            self.proc.wait()
            return
        with stream:
            for raw in iter(stream.readline, b''):
                line = raw.decode('utf-8', 'replace').rstrip()
                if not line:
                    continue
                if line.startswith(('AV:', 'A:')):
                    # Playback position spam; useless once it is in a file.
                    continue
                logger.info('mpv: ' + line)
        self.proc.wait()

    def start_mpv(self):
        """Start mpv thread
        """
        error_time = 3
        while self.running and error_time > 0:
            self.set_state_speed('1')
            # mpv default params
            params = [
                self.path,
                '--input-ipc-server={}'.format(self.mpv_sock),
                '--image-display-duration=inf',
                '--idle=yes',
                # mpv's diagnostics are the only way to find out why a stream
                # will not play (403 from an expired CDN URL, an unsupported
                # codec, a demuxer that gives up). They are captured in
                # drain_mpv_output(). Keep the per-frame position/status spam
                # out of the file, it would otherwise be ~10 lines a second.
                '--msg-level=status=warn,cplayer=warn',
                '--on-all-workspaces',
                '--hwdec=yes',
                '--save-position-on-quit=yes',
                '--script-opts=osc-timetotal=yes,osc-layout=bottombar,' +
                'osc-title=${title},osc-showwindowed=yes,' +
                'osc-seekbarstyle=bar,osc-visibility=auto'
            ]

            ontop = Setting.get(SettingProperty.PlayerOntop,
                                default=SettingProperty.PlayerOntop_True.value)
            if ontop:
                params.append('--ontop')

            # set player size
            player_size = Setting.get(SettingProperty.PlayerSize,
                                      default=SettingProperty.PlayerSize_Normal.value)
            if player_size <= SettingProperty.PlayerSize_Large.value:
                params.append('--autofit={}%'.format(
                    int(15 - 2.5 * player_size + 7.5 * player_size ** 2)))
            elif player_size == SettingProperty.PlayerSize_Auto.value:
                params.append('--autofit-larger=90%')
            elif player_size == SettingProperty.PlayerSize_FullScreen.value:
                params.append('--fullscreen')

            # Player position.
            #
            # Deliberately pass no --geometry. mpv resolves "--geometry=WxH+X+Y"
            # and "X%:Y%" against the whole desktop Cocoa reports, and it then
            # overrides whatever it was given with the video's own size, so the
            # window lands wherever that arithmetic says rather than where the
            # user asked. On a setup where the screen list still contains an
            # entry with no physical screen behind it, that arithmetic puts the
            # window off-screen: nothing is logged, the window exists, playback
            # runs, and it is never visible.
            #
            # Left alone, mpv centres the window on the primary screen and gets
            # it right. The Player Position setting is honoured by moving the
            # window ourselves once it exists -- see _place_window().

            # set lua scripts
            scripts_path = Setting.get_base_path('scripts')
            if os.path.exists(scripts_path):
                scripts = os.listdir(scripts_path)
                scripts = filter(lambda s: s.endswith('.lua'), scripts)
                for script in scripts:
                    path = os.path.join(scripts_path, script)
                    params.append('--script={}'.format(path))

            # set darwin only options
            if sys.platform == 'darwin':
                # --ontop alone already keeps the window above normal windows.
                #
                # Do NOT add --ontop-level=system. With the window backend in
                # mpv 0.41 on macOS 15 it lands the video window on
                # kCGDesktopWindowLevel (CG window layer 26), i.e. underneath
                # the desktop icons and wallpaper. The window still exists and
                # still reports onscreen=YES with the right size, and playback
                # runs normally -- vo-configured is true and frames decode --
                # so nothing in the logs or the DLNA session looks wrong. It is
                # simply never visible, which looks exactly like a player that
                # does not start.
                #
                # plain --ontop puts the window on layer 0, which is the normal
                # floating-window level and is what "player on top" should mean.
                params += [
                    '--on-all-workspaces',
                    '--macos-app-activation-policy=accessory',
                ]

            # set hardware
            hw = Setting.get(SettingProperty.PlayerHW,
                             default=SettingProperty.PlayerHW_Enable.value)
            if hw == SettingProperty.PlayerHW_Disable.value:
                params.remove('--hwdec=yes')
            elif hw == SettingProperty.PlayerHW_Force.value:
                params.append('--macos-force-dedicated-gpu=yes')

            # start mpv
            logger.info("mpv starting")
            cherrypy.engine.publish('mpv_start')
            try:
                self.proc = subprocess.Popen(
                    params,
                    # mpv writes its terminal output to stdout, not stderr, so
                    # stdout has to be the pipe. Leaving it on DEVNULL is what
                    # kept "HTTP error 403 Forbidden" out of the log even after
                    # --no-terminal came off.
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    stdin=subprocess.PIPE,
                    env=Setting.get_system_env())
                # Drain mpv's output continuously instead of letting it sit in
                # the pipe.
                #
                # --no-terminal used to be passed here, which suppresses every
                # diagnostic mpv writes, so the only thing that ever reached the
                # log was the "mpv restarting" line below -- and a player that
                # fails to open its URL looks exactly like a player that is
                # merely idle. A DLNA stream whose CDN URL has expired answers
                # "HTTP error 403 Forbidden", mpv prints "Failed to open ...",
                # and then it sits there with idle-active=true forever while
                # the DLNA client keeps reporting PLAYING. None of that was
                # visible anywhere. Let mpv log, and drain the pipe into our log
                # so it cannot fill up and block mpv.
                self.drain_mpv_output()
            except Exception as e:
                logger.error(e)
            logger.info("mpv stopped")
            if self.running and not self.ipc_once_connected:
                # There should be a problem with the MPV startup parameters
                time.sleep(1)
                error_time -= 1
                logger.error("mpv restarting")
        if error_time <= 0:
            # some thing wrong with mpv
            cherrypy.engine.publish("app_notify", "Macast", "MPV Can't start")
            logger.error("mpv cannot start")
            threading.Thread(target=lambda: Setting.stop_service(), name="MPV_STOP_SERVICE").start()

    def start(self):
        """Start mpv and mpv ipc
        """
        super(MPVRenderer, self).start()
        logger.info("starting mpv and mpv ipc")
        self.mpv_thread = threading.Thread(target=self.start_mpv, name="MPV_THREAD")
        self.mpv_thread.start()
        self.ipc_thread = threading.Thread(target=self.start_ipc, name="MPV_IPC_THREAD")
        self.ipc_thread.start()

    def stop(self):
        """Stop mpv and mpv ipc
        """
        super(MPVRenderer, self).stop()
        logger.info("stoping mpv and mpv ipc")
        # stop mpv
        self.send_command(['quit'])
        if self.proc is not None:
            self.proc.terminate()
        try:
            os.waitpid(-1, 1)
        except Exception as e:
            logger.error(e)
        self.mpv_thread.join()
        # stop mpv ipc
        self.ipc_running = False
        self.ipc_thread.join()

    def reload(self):
        """Reload MPV
        If the MPV is playing content before reloading the player,
        then continue playing the previous content after the reload
        """
        uri = self.protocol.get_state_url()

        def loadfile():
            logger.debug("mpv loadfile")
            protocols = cherrypy.engine.publish('get_protocol')
            if len(protocols) > 0:
                protocol = protocols.pop()
                position = protocol.get_state_position()
                self.send_command(['loadfile', uri, 'replace', f'start={position}'])
            else:
                self.send_command(['loadfile', uri, 'replace'])
            self.send_command(['set_property', 'title', self.title])
            cherrypy.engine.unsubscribe('mpvipc_start', loadfile)

        def restart():
            self.stop()
            self.start()

        if self.protocol.get_state_transport_state() == 'PLAYING':
            cherrypy.engine.subscribe('mpvipc_start', loadfile)

        threading.Thread(target=restart, args=()).start()


class SettingProperty(Enum):
    PlayerHW = 100
    PlayerHW_Disable = 0
    PlayerHW_Enable = 1
    PlayerHW_Force = 2

    PlayerSize = 200
    PlayerSize_Small = 0
    PlayerSize_Normal = 1
    PlayerSize_Large = 2
    PlayerSize_Auto = 3
    PlayerSize_FullScreen = 4

    PlayerPosition = 300
    PlayerPosition_LeftTop = 0
    PlayerPosition_LeftBottom = 1
    PlayerPosition_RightTop = 2
    PlayerPosition_RightBottom = 3
    PlayerPosition_Center = 4

    PlayerOntop = 400
    PlayerOntop_False = 0
    PlayerOntop_True = 1

    PlayerDefaultVolume = 500


class MPVRendererSetting(RendererSetting):
    def __init__(self):
        self.playerPositionItem = None
        self.playerSizeItem = None
        self.playerHWItem = None
        Setting.load()
        self.setting_player_size = Setting.get(SettingProperty.PlayerSize,
                                               SettingProperty.PlayerSize_Normal.value)
        self.setting_player_position = Setting.get(SettingProperty.PlayerPosition,
                                                   SettingProperty.PlayerPosition_RightTop.value)
        self.setting_player_hw = Setting.get(SettingProperty.PlayerHW,
                                             SettingProperty.PlayerHW_Enable.value)
        self.setting_player_ontop = Setting.get(SettingProperty.PlayerOntop,
                                                SettingProperty.PlayerOntop_True.value)

    def build_menu(self):
        self.playerPositionItem = MenuItem(_("Player Position"),
                                           children=App.build_menu_item_group([
                                               _("LeftTop"),
                                               _("LeftBottom"),
                                               _("RightTop"),
                                               _("RightBottom"),
                                               _("Center")
                                           ], self.on_renderer_position_clicked))
        self.playerSizeItem = MenuItem(_("Player Size"),
                                       children=App.build_menu_item_group([
                                           _("Small"),
                                           _("Normal"),
                                           _("Large"),
                                           _("Auto"),
                                           _("Fullscreen")
                                       ], self.on_renderer_size_clicked))
        self.playerOntopItem = MenuItem(_("Player Ontop"), self.on_renderer_ontop_clicked)

        has_dedicated_gpu = False
        # Force dedicated GPU only works on MacOS
        if sys.platform == 'darwin':
            try:
                res, gpu_info = Setting.system_shell(
                    ['system_profiler', '-json', '-timeout', '10', 'SPDisplaysDataType'])
                if res == 0:
                    gpu_info = json.loads(gpu_info)
                    has_dedicated_gpu = len(gpu_info['SPDisplaysDataType']) > 1
                    logger.error("GPU list:")
                    for gpu in gpu_info['SPDisplaysDataType']:
                        logger.error('GPU:' + gpu['sppci_model'])
            except Exception as e:
                logger.error("Error get gpu info")

        if has_dedicated_gpu:
            self.playerHWItem = MenuItem(_("Hardware Decode"),
                                         children=App.build_menu_item_group([
                                             _("Hardware Decode"),
                                             _("Force Dedicated GPU")
                                         ], self.on_renderer_hw_clicked))
            if self.setting_player_hw == SettingProperty.PlayerHW_Disable.value:
                self.playerHWItem.items()[1].enabled = False
            else:
                self.playerHWItem.items()[0].checked = True
            self.playerHWItem.items()[1].checked = (
                    self.setting_player_hw == SettingProperty.PlayerHW_Force.value)
        else:
            self.playerHWItem = MenuItem(_("Hardware Decode"),
                                         self.on_renderer_hw_toggled)
            if self.setting_player_hw != SettingProperty.PlayerHW_Disable:
                self.playerHWItem.checked = True
        self.playerPositionItem.items()[self.setting_player_position].checked = True
        self.playerSizeItem.items()[self.setting_player_size].checked = True
        self.playerOntopItem.checked = True if self.setting_player_ontop == 1 else False

        return [
            MenuItem(_("Player Settings"), enabled=False),
            self.playerPositionItem,
            self.playerSizeItem,
            self.playerHWItem,
            self.playerOntopItem,
        ]

    def reloadPlayer(self):
        cherrypy.engine.publish('app_notify',
                                _("Reload Player"),
                                _("please wait"),
                                sound=False)
        cherrypy.engine.publish('reload_renderer')

    def on_renderer_ontop_clicked(self, item):
        item.checked = not item.checked
        Setting.set(SettingProperty.PlayerOntop, 1 if item.checked else 0)
        self.reloadPlayer()

    def on_renderer_position_clicked(self, item):
        for i in self.playerPositionItem.items():
            i.checked = False
        item.checked = True
        Setting.set(SettingProperty.PlayerPosition, item.data)
        self.reloadPlayer()

    def on_renderer_hw_toggled(self, item):
        item.checked = not item.checked
        Setting.set(SettingProperty.PlayerHW, 1 if item.checked else 0)
        self.reloadPlayer()

    def on_renderer_hw_clicked(self, item):
        item.checked = not item.checked
        if item.data == 0:
            # click Hardware Decode
            if item.checked:
                # Change to Default Hardware Decode
                Setting.set(SettingProperty.PlayerHW, SettingProperty.PlayerHW_Enable.value)
                self.playerHWItem.items()[1].enabled = True
            else:
                # Change to Software Decode
                Setting.set(SettingProperty.PlayerHW, SettingProperty.PlayerHW_Disable.value)
                self.playerHWItem.items()[1].checked = False
                self.playerHWItem.items()[1].enabled = False
        else:
            # click Force Dedicated GPU Decode
            if item.checked:
                # Change to Force Dedicated GPU Decode
                Setting.set(SettingProperty.PlayerHW, SettingProperty.PlayerHW_Force.value)
            else:
                # Change to Default Hardware Decode
                Setting.set(SettingProperty.PlayerHW, SettingProperty.PlayerHW_Enable.value)
        self.reloadPlayer()

    def on_renderer_size_clicked(self, item):
        for i in self.playerSizeItem.items():
            i.checked = False
        item.checked = True
        Setting.set(SettingProperty.PlayerSize, item.data)
        if item.data == SettingProperty.PlayerSize_Auto.value:
            # set player position to center
            for i in self.playerPositionItem.items():
                i.checked = False
            self.playerPositionItem.items()[4].checked = True
            Setting.set(SettingProperty.PlayerPosition, SettingProperty.PlayerPosition_Center.value)
        self.reloadPlayer()
