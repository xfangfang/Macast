# Copyright (c) 2021 by xfangfang. All Rights Reserved.

import os
import sys
import gettext
import logging
from macast import Setting
from macast.macast import gui
from macast_renderer.mpv import MPVRenderer

logger = logging.getLogger("Macast")
logger.setLevel(logging.DEBUG)


def get_base_path(path="."):
    if getattr(sys, 'frozen', False) and hasattr(sys, '_MEIPASS'):
        base_path = sys._MEIPASS
    else:
        base_path = os.getcwd()
    return os.path.join(base_path, path)


try:
    locale = Setting.get_locale()
    lang = gettext.translation('macast', localedir=get_base_path('i18n'), languages=[locale])
    lang.install()
    logger.error("Macast Loading Language: {}".format(locale))
except Exception as e:
    import builtins
    builtins.__dict__['_'] = gettext.gettext
    logger.error("Macast Loading Default Language en_US")

if __name__ == '__main__':
    Setting.load()
    mpv_path = 'mpv'
    if sys.platform == 'darwin':
        mpv_path = get_base_path('bin/MacOS/mpv')
    elif sys.platform == 'win32':
        mpv_path = get_base_path('bin/mpv.exe')
    gui(MPVRenderer(_, mpv_path), _)
