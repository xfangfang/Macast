# Copyright (c) 2021 by xfangfang. All Rights Reserved.

import os
import sys
import logging
from macast import Setting
from macast.macast import gui

logger = logging.getLogger("Macast")


def get_base_path(path="."):
    if getattr(sys, 'frozen', False) and hasattr(sys, '_MEIPASS'):
        base_path = sys._MEIPASS
    else:
        base_path = os.getcwd()
    return os.path.join(base_path, path)


def set_mpv_default_path():
    mpv_path = 'mpv'
    if sys.platform == 'darwin':
        mpv_path = get_base_path('bin/MacOS/mpv')
    elif sys.platform == 'win32':
        mpv_path = get_base_path('bin/mpv.exe')
    Setting.mpv_default_path = mpv_path
    return mpv_path


if __name__ == '__main__':
    set_mpv_default_path()
    gui()
