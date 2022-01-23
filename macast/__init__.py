# Copyright (c) 2021 by xfangfang. All Rights Reserved.


from .macast import Service, Macast, gui, cli
from .utils import SETTING_DIR, Setting, SettingProperty
from .renderer import Renderer, RendererSetting
from .plugin import RendererPlugin
from .gui import App, MenuItem, Platform

__version__ = '0.7'
__url__ = 'https://github.com/xfangfang/Macast'
__author__ = 'xfangfang'
__email__ = 'xfangfang@126.com'
