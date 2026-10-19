# Copyright (c) 2021 by xfangfang. All Rights Reserved.

import os
import sys
import gettext
import logging
from macast import Setting, SETTING_DIR
from macast.macast import gui

logger = logging.getLogger("Macast")
logger.setLevel(logging.DEBUG)


def get_base_path(path="."):
    if getattr(sys, 'frozen', False) and hasattr(sys, '_MEIPASS'):
        base_path = sys._MEIPASS
    else:
        base_path = os.getcwd()
    return os.path.join(base_path, path)


def set_mpv_default_path():
    """Locate the bundled mpv binary.

    On macOS the mpv tree ships as a self-contained bundle under
    Contents/Resources/bin: the binary in MacOS/, its 97 dylibs in MacOS/lib/,
    libMoltenVK.dylib in Frameworks/ and the Vulkan ICD manifest in
    Resources/vulkan/icd.d. Splitting that tree makes mpv start but fail every
    frame with "Failed initializing any suitable GPU context!", so all of it has
    to stay where the bundle expects it.

    PyInstaller's sys._MEIPASS is Contents/Frameworks, and the paths that matter
    live next to it, so anchor on sys.executable (Contents/MacOS/Macast) and walk
    out to Contents/ properly. Do not derive them from get_base_path('.'):
    os.path.dirname('<contents>/Frameworks/.') is still '<contents>/Frameworks',
    not '<contents>', which silently produces the wrong path.
    """
    mpv_path = 'mpv'
    if sys.platform == 'darwin':
        if getattr(sys, 'frozen', False):
            contents = os.path.dirname(os.path.dirname(os.path.abspath(sys.executable)))
        else:
            contents = os.getcwd()
        candidates = [
            # PyInstaller onedir, where mpv is bundled next to Resources.
            os.path.join(contents, 'Resources', 'bin', 'MacOS', 'mpv'),
            # Historical py2app layout, kept so an old bundle still runs.
            os.path.join(contents, 'Frameworks', 'bin', 'MacOS', 'mpv'),
            os.path.join(contents, 'bin', 'MacOS', 'mpv'),
            get_base_path('bin/MacOS/mpv'),
        ]
        for candidate in candidates:
            if os.path.exists(candidate):
                mpv_path = candidate
                break
        else:
            # Falling back to a path we already know is wrong just turns a clear
            # error into a silent renderer that never produces a frame.
            logger.error('bundled mpv not found, tried: %s', candidates)
            raise FileNotFoundError(
                'mpv not found in the application bundle: ' + ', '.join(candidates))
    elif sys.platform == 'win32':
        mpv_path = get_base_path('bin/mpv.exe')
    Setting.mpv_default_path = mpv_path
    return mpv_path


def get_lang():
    locale = Setting.get_locale()
    i18n_path = get_base_path('i18n')
    if not os.path.exists(os.path.join(i18n_path, locale, 'LC_MESSAGES', 'macast.mo')):
        locale = locale.split("_")[0]
    logger.error("Macast Loading Language: {}".format(locale))
    try:
        lang = gettext.translation('macast', localedir=i18n_path, languages=[locale])
        lang.install()
    except Exception:
        import builtins
        builtins.__dict__['_'] = gettext.gettext
        logger.error("Macast Loading Default Language en_US")


def setup_logging():
    """Send Python logging to a file next to the settings.

    A bundled .app has no terminal, so every logger.error() in the renderer
    and protocol layers goes nowhere. The DLNA side still answers 200 and the
    player still starts, which makes a failure between "phone sent the media"
    and "player received the media" completely invisible. Write it to
    macast_python.log so those messages survive a restart.
    """
    log_path = os.path.join(SETTING_DIR, 'macast_python.log')
    handler = logging.FileHandler(log_path, encoding='utf-8')
    handler.setFormatter(logging.Formatter(
        '%(asctime)s %(levelname)s %(name)s: %(message)s'))
    root = logging.getLogger()
    # CherryPy already writes its own file handler for the access log; adding
    # ours at the root keeps the existing behaviour and adds to it.
    if not any(isinstance(h, logging.FileHandler)
               and getattr(h, 'baseFilename', '').endswith('macast_python.log')
               for h in root.handlers):
        root.addHandler(handler)
    root.setLevel(logging.DEBUG)
    logger.info('Macast starting, python log at %s', log_path)


def clear_env():
    # todo clear pyinstaller file on start
    # Only truncate the CherryPy access log. Keeping the file (and its handler)
    # means the previous run's Python-side errors are still readable instead of
    # vanishing exactly when they are needed.
    log_path = os.path.join(SETTING_DIR, 'macast.log')
    try:
        with open(log_path, 'w'):
            pass
    except Exception:
        pass


if __name__ == '__main__':
    setup_logging()
    clear_env()
    get_lang()
    set_mpv_default_path()
    gui(lang=_)
