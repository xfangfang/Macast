"""Macast is a DLNA renderer
It's a menu bar application which using mpv as default player.
You can push videos, pictures or musics from your mobile phone to your computer.

Copyright (c) 2021 by xfangfang. All Rights Reserved.
<https://github.com/xfangfang/Macast/wiki>
"""

from .__pkginfo__ import __version__, __url__, __email__, __author__

from .macast import Service, Macast, gui, cli
from .utils import SETTING_DIR, Setting, SettingProperty
from .renderer import Renderer
from .plugin import RendererPlugin
from .gui import App, MenuItem, Platform, Tool
