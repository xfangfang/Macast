# Copyright (c) 2021 by xfangfang. All Rights Reserved.

import os
import sys
import threading
import uuid
import json
import time
import ctypes
from typing import Any

import appdirs
import logging
import platform
import gettext
import cherrypy
import subprocess
from enum import Enum
import netifaces as ni
import tempfile

if sys.platform != "win32":
    import fcntl
if sys.platform == 'darwin':
    from AppKit import NSBundle
elif sys.platform == 'win32':
    import locale
    import win32api
    import win32con

from .__pkginfo__ import __version__, __version_num__

logger = logging.getLogger("Utils")
_ = gettext.gettext
DEFAULT_PORT = 0
SETTING_DIR = appdirs.user_config_dir('Macast', 'xfangfang')
LOG_DIR = appdirs.user_log_dir('Macast', 'xfangfang')
PROTOCOL_DIR = 'protocol'
RENDERER_DIR = 'renderer'
TOOL_DIR = 'tool'
LOG_LEVEL = {
    'ERROR': 40,
    'INFO': 20,
    'DEBUG': 10,
    'ALL': 0
}


class SettingProperty(Enum):
    USN = 0
    CheckUpdate = 1
    StartAtLogin = 2
    MenubarIcon = 3
    ApplicationPort = 4
    DLNA_FriendlyName = 5
    Macast_Renderer = 6
    Macast_Protocol = 7
    Blocked_Interfaces = 8
    Additional_Interfaces = 9
    Macast_Log = 10
    Macast_Setting_Port = 11
    Macast_Tool = 12
    SingleMode = 13


class Setting:
    setting = {}
    version = None
    setting_path = os.path.join(SETTING_DIR, "macast_setting.json")
    last_ip = None
    base_path = None
    friendly_name = "Macast({})".format(platform.node())
    temp_friendly_name = None
    mpv_default_path = 'mpv'
    log_level = None

    @staticmethod
    def save():
        """Save user settings
        """
        if not os.path.exists(SETTING_DIR):
            os.makedirs(SETTING_DIR)
        with open(Setting.setting_path, "w") as f:
            json.dump(obj=Setting.setting, fp=f, sort_keys=True, indent=4)

    @staticmethod
    def load():
        """Load user settings
        """
        logger.info("Load Setting")
        if Setting.version is None:
            Setting.version = __version_num__
        if bool(Setting.setting) is False:
            if not os.path.exists(Setting.setting_path):
                Setting.setting = {}
            else:
                try:
                    with open(Setting.setting_path, "r") as f:
                        Setting.setting = json.load(fp=f)
                    logger.info(Setting.setting)
                except Exception as e:
                    logger.error(e)
        return Setting.setting

    @staticmethod
    def reload():
        Setting.setting = None
        Setting.load()

    @staticmethod
    def get_system_version():
        """Get system version
        """
        return str(platform.release())

    @staticmethod
    def get_system():
        """Get system name
        """
        return str(platform.system())

    @staticmethod
    def get_version() -> float:
        """Get application version in float
        """
        return Setting.version

    @staticmethod
    def get_version_tag() -> str:
        """Get application version in string
        112.45 => 112.4.5
        """
        return __version__

    @staticmethod
    def get_friendly_name():
        """Get application friendly name
        This name will show in the device search list of the DLNA client
        and as player window default name.
        """
        if Setting.temp_friendly_name:
            return Setting.temp_friendly_name
        return Setting.get(SettingProperty.DLNA_FriendlyName, Setting.friendly_name)

    @staticmethod
    def set_temp_friendly_name(name):
        Setting.temp_friendly_name = name

    @staticmethod
    def get_usn(refresh=False):
        """Get device unique identification
        """
        dlna_id = str(uuid.uuid4())
        if not refresh:
            dlna_id_temp = Setting.get(SettingProperty.USN, dlna_id)
            if dlna_id == dlna_id_temp:
                Setting.set(SettingProperty.USN, dlna_id)
            return dlna_id_temp
        else:
            Setting.set(SettingProperty.USN, dlna_id)
            return dlna_id

    @staticmethod
    def is_ip_changed():
        ip_now = Setting.update_ip()
        if Setting.last_ip != ip_now:
            Setting.last_ip = ip_now
            return True
        return False

    @staticmethod
    def get_ip():
        if Setting.last_ip is None:
            Setting.last_ip = Setting.update_ip()
        return Setting.last_ip

    @staticmethod
    def update_ip():
        last_ip = []
        gateways = ni.gateways()  # {type: [{ip, interface, default},{},...], type: []}
        interfaces = set(Setting.get(SettingProperty.Additional_Interfaces, []))
        interface_type = [ni.AF_INET, ni.AF_LINK]
        for t in interface_type:
            if t in gateways:
                for i in gateways[t]:
                    if len(i) > 1:
                        interfaces.add(i[1])
        for i in Setting.get(SettingProperty.Blocked_Interfaces, []):
            if i in interfaces:
                interfaces.remove(i)
        for i in interfaces:
            try:
                iface = ni.ifaddresses(i)
            except ValueError as e:
                continue
            if ni.AF_INET in iface:
                for j in iface[ni.AF_INET]:
                    if 'addr' in j and 'netmask' in j:
                        last_ip.append((j['addr'], j['netmask']))
        ip_now = set(last_ip)
        logger.debug(f'interfaces: {interfaces} ip: {ip_now}')
        return ip_now

    @staticmethod
    def get_port():
        """Get application port
        """
        return Setting.get(SettingProperty.ApplicationPort, DEFAULT_PORT)

    @staticmethod
    def get_setting_port():
        """Get application port
        """
        return Setting.get(SettingProperty.Macast_Setting_Port, DEFAULT_PORT)

    @staticmethod
    def get_locale():
        """Get the language settings of the system
        Default: en_US
        """
        if sys.platform == 'darwin':
            lang = subprocess.check_output(
                ["osascript", "-e",
                 "user locale of (get system info)"]).decode().strip()
        elif sys.platform == 'win32':
            windll = ctypes.windll.kernel32
            lang = locale.windows_locale[windll.GetUserDefaultUILanguage()]
        else:
            for v in ['LANGUAGE', 'LANG', 'LC_MESSAGES', 'LC_ALL']:
                lang = os.environ.get(v)
                if lang is not None:
                    break
            else:
                return 'en_US'
            lang = lang.split(':')[0].split('.')[0]
        return lang

    @staticmethod
    def get(prop, default: Any = 1):
        """Get application settings
        """
        if not bool(Setting.setting):
            Setting.load()

        if isinstance(prop, str):
            prop_name = prop
        else:
            prop_name = prop.name

        if prop_name in Setting.setting:
            return Setting.setting[prop_name]
        Setting.setting[prop_name] = default
        return default

    @staticmethod
    def set(prop, data):
        """Set application settings
        """

        if isinstance(prop, str):
            prop_name = prop
        else:
            prop_name = prop.name

        Setting.setting[prop_name] = data
        Setting.save()

    @staticmethod
    def system_shell(shell):
        result = subprocess.run(shell, stdout=subprocess.PIPE)
        return result.returncode, result.stdout.decode('UTF-8').strip()

    @staticmethod
    def set_start_at_login(launch):
        if sys.platform == 'darwin':
            app_path = NSBundle.mainBundle().bundlePath()
            if not app_path.startswith("/Applications"):
                return 1, _("You need move Macast.app to Applications folder")
            app_name = app_path.split("/")[-1].split(".")[0]
            res = Setting.system_shell(
                ['osascript',
                 '-e',
                 'tell application "System Events" ' +
                 'to get the name of every login item'])
            if res[0] == 1:
                return 1, _("Cannot access System Events")
            apps = list(map(lambda app: app.strip(), res[1].split(",")))
            # apps which start at login
            if launch:
                if app_name in apps:
                    return 0, "Macast is already in login items"
                res = Setting.system_shell(
                    ['osascript',
                     '-e',
                     'tell application "System Events" ' +
                     'to make login item at end with properties ' +
                     '{{name: "{}",path:"{}", hidden:false}}'.format(
                         app_name, app_path)
                     ])
            else:
                if app_name not in apps:
                    return 0, "Macast is already not in login items"
                res = Setting.system_shell(
                    ['osascript',
                     '-e',
                     'tell application "System Events" ' +
                     'to delete login item "{}"'.format(app_name)])
            return res
        elif sys.platform == 'win32':
            """Find the path of Macast.exe so as to create shortcut.
            """
            if "python" in os.path.basename(sys.executable).lower():
                return 1, _("Not support to set start at login")

            key = win32api.RegOpenKey(win32con.HKEY_CURRENT_USER,
                                      r'Software\Microsoft\Windows\CurrentVersion\Run',
                                      0,
                                      win32con.KEY_SET_VALUE)
            logger.info(sys.executable)
            if launch:
                try:
                    win32api.RegSetValueEx(key, 'Macast', 0, win32con.REG_SZ, sys.executable)
                    win32api.RegCloseKey(key)
                except Exception as e:
                    logger.error(e)
                    # cherrypy.engine.publish("app_notify", "ERROR", f"{e}")
                return 0, 1
            else:
                try:
                    win32api.RegDeleteValue(key, 'Macast')
                    win32api.RegCloseKey(key)
                except Exception as e:
                    logger.error(e)
                    # cherrypy.engine.publish("app_notify", "ERROR", f"{e}")
                return 0, 1
        else:
            return 1, _('Not support current platform')

    @staticmethod
    def get_base_path(path="."):
        """PyInstaller creates a temp folder and stores path in _MEIPASS
            https://stackoverflow.com/a/13790741
            see also: https://pyinstaller.readthedocs.io/en/stable/\
                runtime-information.html#run-time-information
        """
        logger.warning("Setting.get_base_path will be removed in next version.")
        if Setting.base_path is not None:
            return os.path.join(Setting.base_path, path)
        if getattr(sys, 'frozen', False) and hasattr(sys, '_MEIPASS'):
            Setting.base_path = sys._MEIPASS
        else:
            Setting.base_path = os.path.join(os.path.dirname(__file__), '.')
        return os.path.join(Setting.base_path, path)

    @staticmethod
    def get_server_info():
        return '{}/{} UPnP/1.0 Macast/{}'.format(Setting.get_system(),
                                                 Setting.get_system_version(),
                                                 Setting.get_version_tag())

    @staticmethod
    def get_system_env():
        # Get system env(for GNU/Linux and *BSD).
        # https://pyinstaller.readthedocs.io/en/stable/runtime-information.html#run-time-information
        env = dict(os.environ)
        logger.debug(env)
        lp_key = 'LD_LIBRARY_PATH'
        lp_orig = env.get(lp_key + '_ORIG')
        if lp_orig is not None:
            env[lp_key] = lp_orig
        else:
            env.pop(lp_key, None)
        return env

    @staticmethod
    def stop_service():
        """Stop all DLNA threads
        stop MPV
        stop DLNA HTTP Server
        stop SSDP
        stop SSDP notify thread
        """
        if cherrypy.engine.state in [cherrypy.engine.states.STOPPED,
                                     cherrypy.engine.states.STOPPING,
                                     cherrypy.engine.states.EXITING,
                                     ]:
            return
        while cherrypy.engine.state != cherrypy.engine.states.STARTED:
            time.sleep(0.5)
        cherrypy.engine.exit()

    @staticmethod
    def is_service_running():
        return cherrypy.engine.state in [cherrypy.engine.states.STARTING,
                                         cherrypy.engine.states.STARTED,
                                         ]

    @staticmethod
    def restart():
        if sys.platform == 'darwin' and sys.executable.endswith("Contents/MacOS/python"):
            # run from py2app build
            Setting.stop_service()
            executable = sys.executable[:-6] + 'Macast'
            os.execv(executable, [executable, executable])
        elif sys.platform == 'linux' and getattr(sys, 'frozen', False) and hasattr(sys, '_MEIPASS'):
            # run from pyinstaller build on linux
            Setting.stop_service()
            env = Setting.get_system_env()
            executable = sys.executable
            os.execve(executable, [executable, executable], env)
        else:
            cherrypy.engine.restart()

    @staticmethod
    def restart_async():
        threading.Thread(target=Setting.restart, name="RESTART_THREAD", daemon=True).start()

    @staticmethod
    def setup_logger():
        if Setting.log_level is not None:
            return LOG_LEVEL.get(Setting.log_level, 20)
        Setting.log_level = Setting.get(SettingProperty.Macast_Log, 'INFO').upper()

        log_level = LOG_LEVEL.get(Setting.log_level, 20)
        log_file = os.path.join(SETTING_DIR, 'macast.log')
        log_format = '%(levelname)s: [%(asctime)s] - %(name)s/%(funcName)s/%(threadName)s|%(thread)d[line:%(lineno)d] - %(message)s'
        logging.basicConfig(
            level=log_level,
            format=log_format,
            handlers=[logging.StreamHandler(), logging.FileHandler(log_file, mode='w', encoding='utf-8')]
        )

        logger.info(f'Using log level: {Setting.log_level}, {log_level}')
        logger.info(f'Load Setting: {Setting.setting}')

        return log_level


class XMLPath(Enum):
    BASE_PATH = os.path.dirname(__file__)
    DESCRIPTION = BASE_PATH + '/xml/Description.xml'
    AV_TRANSPORT = BASE_PATH + '/xml/AVTransport.xml'
    CONNECTION_MANAGER = BASE_PATH + '/xml/ConnectionManager.xml'
    RENDERING_CONTROL = BASE_PATH + '/xml/RenderingControl.xml'
    SETTING_PAGE = BASE_PATH + '/xml/setting.html'
    PROTOCOL_INFO = BASE_PATH + '/xml/SinkProtocolInfo.csv'

class SingleInstanceException(BaseException):
    pass


class SingleInstance(object):

    def __init__(self, flavor_id="", lockfile=""):
        self.initialized = False
        if lockfile:
            self.lockfile = lockfile
        else:
            basename = os.path.splitext(SETTING_DIR)[0].replace(
                "/", "-").replace(":", "").replace("\\", "-") + '-%s' % flavor_id + '.lock'
            
            self.lockfile = os.path.normpath(
                tempfile.gettempdir() + '/' + basename)

        logger.debug("SingleInstance lockfile: " + self.lockfile)
        if sys.platform == 'win32':
            try:
                # file already exists, we try to remove (in case previous
                # execution was interrupted)
                if os.path.exists(self.lockfile):
                    os.unlink(self.lockfile)
                self.fd = os.open(
                    self.lockfile, os.O_CREAT | os.O_EXCL | os.O_RDWR)
            except OSError:
                type, e, tb = sys.exc_info()
                if e.errno == 13:
                    logger.error(
                        "Another instance is already running, quitting.")
                    raise SingleInstanceException()
                print(e.errno)
                raise
        else:  # non Windows
            self.fp = open(self.lockfile, 'w')
            self.fp.flush()
            try:
                fcntl.lockf(self.fp, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except IOError:
                logger.warning(
                    "Another instance is already running, quitting.")
                raise SingleInstanceException()
        self.initialized = True

    def __del__(self):
        if not self.initialized:
            return
        try:
            if sys.platform == 'win32':
                if hasattr(self, 'fd'):
                    os.close(self.fd)
                    os.unlink(self.lockfile)
            else:
                fcntl.lockf(self.fp, fcntl.LOCK_UN)
                # os.close(self.fp)
                if os.path.isfile(self.lockfile):
                    os.unlink(self.lockfile)
        except Exception as e:
            if logger:
                logger.warning(e)
            else:
                print("Unloggable error: %s" % e)
            sys.exit(-1)



class AssetsPath:
    BASE_PATH = os.path.dirname(__file__)
    I18N = os.path.join(BASE_PATH, 'i18n')
    XML = os.path.join(BASE_PATH, 'xml')
    ASSETS = os.path.join(BASE_PATH, 'assets')
    SCRIPTS = os.path.join(BASE_PATH, 'scripts')
    LOG = os.path.join(SETTING_DIR, 'macast.log')

    @staticmethod
    def join(*args):
        return os.path.join(AssetsPath.BASE_PATH, *args)


def load_xml(path):
    try:
        with open(path, encoding="utf-8") as f:
            xml = f.read()
    except Exception as e:
        xml = ''
        logger.exception(f'Error reading {path}', exc_info=e)
    return xml


def notify_error(msg=None):
    """publish a notification when error occured
    """

    def wrapper_fun(fun):
        def wrapper(*args, **kwargs):
            nonlocal msg
            try:
                return fun(*args, **kwargs)
            except Exception as e:
                if msg is None:
                    msg = str(e)
                logger.exception(msg, exc_info=e)
                cherrypy.engine.publish('app_notify', 'Error', msg)

        return wrapper

    return wrapper_fun


def publish_method(func):
    def wrap(*args, **kwargs):
        func(*args, **kwargs)
        cherrypy.engine.publish(func.__name__, *args, **kwargs)

    return wrap


def format_class_name(instance):
    """
    eg1: DLNAHandler -> DLNA Handler
    eg2: AabcBabc -> Aabc Babc
    :param instance:
    :return:
    """
    name = instance.__class__.__name__
    res = name[0]
    for i in range(1, len(name) - 1):
        if 'A' <= name[i] <= 'Z' and 'a' <= name[i + 1] <= 'z':
            res += f' {name[i]}'
        else:
            res += name[i]
    res += name[-1]
    return res


def cherrypy_publish(method, default=None):
    res = cherrypy.engine.publish(method)
    if len(res) > 0:
        return res.pop()

    logger.error(f'Unable to run method: {method} return default: {default}')
    if callable(default):
        return default()
    return default


def get_subnet_ip(ip, mask):
    """
    :param ip: eg:192.168.1.123
    :param mask: eg:255.255.255.0
    :return: eg: [192, 168, 1, 0]
    """
    a = [int(n) for n in mask.split('.')]
    b = [int(n) for n in ip.split('.')]
    return [a[i] & b[i] for i in range(4)]
