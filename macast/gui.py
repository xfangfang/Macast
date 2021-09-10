# Copyright (c) 2021 by xfangfang. All Rights Reserved.

import sys
import logging
import subprocess
from enum import Enum
from .utils import Setting

if sys.platform == 'darwin':
    import rumps
else:
    import pystray
    import webbrowser
    from PIL import Image

logger = logging.getLogger("gui")
logger.setLevel(logging.INFO)


class Platform(Enum):
    Darwin = 0
    Win32 = 1
    Others = 2


class MenuItem:
    def __init__(self, text, callback=None, checked=None, enabled=True,
                 children=None, data=None, key=None):
        self.view = None
        if sys.platform == 'darwin':
            self.platform = Platform.Darwin
        elif sys.platform == 'win32':
            self.platform = Platform.Win32
        else:
            self.platform = Platform.Others

        self._text = text
        self.callback = callback
        self.children = children
        self._checked = checked
        self._enabled = enabled
        self.data = data
        self.id = text
        self.key = key

    @property
    def text(self):
        return self._text

    @property
    def checked(self):
        return self._checked

    @property
    def enabled(self):
        return self._enabled

    @text.setter
    def text(self, value):
        self._text = value
        if self.view is None:
            return
        if self.platform == Platform.Darwin:
            self.view.title = self._text

    @checked.setter
    def checked(self, value):
        self._checked = value
        if self.view is None:
            return
        if self.platform == Platform.Darwin:
            self.view.state = 1 if self._checked else 0

    @enabled.setter
    def enabled(self, value):
        self._enabled = value
        if self.view is None:
            return
        if self.platform == Platform.Darwin:
            state = 1 if self._checked else 0
            self.view.set_callback(
                self._rumpsCallback if self._enabled else None,
                self.key)

    def items(self):
        return [] if self.children is None else self.children

    def _pystrayCallback(self, app, item):
        self.callback(self)

    def _rumpsCallback(self, item):
        self.callback(self)


class App:
    def __init__(self, name, icon, menu, template=True):
        self.name = name
        self.icon = icon
        self.app = None
        self.menu = menu
        self.menuDict = {}
        self.template = template
        if sys.platform == 'darwin':
            self.platform = Platform.Darwin
            self.init_platform_darwin()
        elif sys.platform == 'win32':
            self.platform = Platform.Win32
            self.init_platform_win32()
        else:
            self.platform = Platform.Others
            self.init_platform_others()

        if self.platform == Platform.Darwin:
            self.app = rumps.App(self.name,
                                 icon=self.icon,
                                 menu=self._build_menu_rumps(self.menu),
                                 template=self.template,
                                 quit_button=None)
            rumps.debug_mode(True)
        else:
            self.app = pystray.Icon(self.name,
                                    Image.open(self.icon),
                                    menu=pystray.Menu(
                                        lambda:
                                        self._build_menu_pystray(self.menu)))

    def init_platform_darwin(self):
        pass

    def init_platform_win32(self):
        pass

    def init_platform_others(self):
        pass

    def _build_menu_rumps(self, menu):
        items = []
        for item in menu:
            if item is None:
                items.append(None)
            elif item.children is not None:
                menu_item = rumps.MenuItem(item.text)
                items.append([menu_item, self._build_menu_rumps(item.children)])
            else:
                items.append(self._build_menu_item_rumps(item))
        return items

    def _build_menu_item_rumps(self, item):
        callback = item._rumpsCallback if item.enabled else None
        menu_item = rumps.MenuItem(item.text, callback, item.key)
        menu_item.state = 1 if item.checked else 0
        item.view = menu_item
        return menu_item

    def _build_menu_pystray(self, menu):
        items = []
        for item in menu:
            if item is None:
                items.append(pystray.Menu.SEPARATOR)
            elif item.children is not None and len(item.children) > 0:
                menu_item = pystray.MenuItem(
                    item.text, pystray.Menu(
                        *self._build_menu_pystray(item.children)))
                items.append(menu_item)
            else:
                menu_item = pystray.MenuItem(lambda i: i.view.text,
                                             item._pystrayCallback,
                                             lambda i: True if i.view.checked
                                             else None,
                                             enabled=lambda i: i.view.enabled)
                item.view = menu_item
                menu_item.view = item
                items.append(menu_item)
        return items

    def update_icon(self, icon, template=True):
        self.icon = icon
        if self.platform == Platform.Darwin:
            self.app.template = template
            self.app.icon = self.icon
        else:
            self.app.icon = Image.open(self.icon)

    def update_menu(self):
        """ refresh current menu
            only windows and linux needed
        """
        if self.platform != Platform.Darwin:
            self.app.update_menu()

    def set_menu(self, menu):
        self.menu = menu
        if self.platform == Platform.Darwin:
            self.app.menu.clear()
            self.app.menu = self._build_menu_rumps(menu)
        else:
            self.app.menu = pystray.Menu(lambda: self._build_menu_pystray(menu))

    def _find_menu_item_index_by_id(self, id):
        #  TODO find all items
        for i, item in enumerate(self.menu):
            if item.id is not None and item.id == id:
                return i
        logger.error("Canot find id:{}.".format(id))
        return -1

    def append_menu_item_after(self, id, menu_item):
        if self.platform == Platform.Darwin:
            self.app.menu.insert_after(id, self._build_menu_item_rumps(menu_item))
        else:
            index = self._find_menu_item_index_by_id(id)
            print("index: ", index)
            if index != -1:
                self.menu.insert(index + 1, menu_item)
                self.app.update_menu()

    def append_menu_item_before(self, id, menu_item):
        if self.platform == Platform.Darwin:
            self.app.menu.insert_before(id, self._build_menu_item_rumps(menu_item))
        else:
            index = self._find_menu_item_index_by_id(id)
            if index != -1:
                self.menu.insert(index, menu_item)
                self.app.update_menu()

    def remove_menu_item_by_id(self, id):
        if self.platform == Platform.Darwin:
            self.app.menu.pop(id)
        else:
            index = self._find_menu_item_index_by_id(id)
            if index != -1:
                self.menu.pop(index)
                self.app.update_menu()

    def start(self):
        self.app.run()

    def quit(self, _):
        if self.platform == Platform.Darwin:
            rumps.quit_application()
        else:
            try:
                self.app.remove_notification()
            except NotImplementedError as e:
                pass
            self.app.stop()

    def alert(self, content):
        if self.platform == Platform.Darwin:
            rumps.alert(content)
        else:
            self.notification(content, "Macast")

    def notification(self, title, content, sound=True):
        if self.platform == Platform.Darwin:
            rumps.notification(title, "", content, sound=sound)
        else:
            try:
                self.app.notify(message=content, title=title)
            except NotImplementedError as e:
                pass

    def dialog(self, content, callback=None, cancel="Cancel", ok="Ok"):
        if self.platform == Platform.Darwin:
            try:
                res = Setting.system_shell(
                    ['osascript',
                     '-e',
                     'display dialog "{}" buttons {{"{}","{}"}}'.format(
                         content, cancel, ok)
                     ])
                if ok in res[1] and callback:
                    callback()
            except Exception as e:
                self.notification("Error", "Cannot access System Events")
        else:
            self.notification("Macast", content)
            if callback:
                callback()

    def open_browser(self, url):
        if self.platform == Platform.Darwin:
            subprocess.Popen(['open', url])
        elif self.platform == Platform.Win32:
            webbrowser.open(url)
        else:
            try:
                subprocess.Popen("sensible-browser {}".format(url),
                                 shell=True,
                                 env=Setting.get_system_env())
            except Exception as e:
                logger.error(e)
                webbrowser.open(url)

    def open_directory(self, path):
        if self.platform == Platform.Darwin:
            subprocess.Popen(['open', path])
        elif self.platform == Platform.Win32:
            subprocess.Popen(['explorer.exe', path])
        else:
            try:
                subprocess.Popen(['nautilus', path])
            except Exception as e:
                logger.error(str(e))

    @staticmethod
    def build_menu_item_group(titles, callback):
        items = []
        for index, title in enumerate(titles):
            item = MenuItem(title, callback, data=index)
            items.append(item)
        return items


if __name__ == '__main__':
    class DemoApp(App):
        def __init__(self):
            super(DemoApp, self).__init__("Macast",
                                          "assets/menu_light.png",
                                          [MenuItem("Add",
                                                    self.add,
                                                    data=1,
                                                    key="a"),
                                           MenuItem("Remove",
                                                    self.remove,
                                                    data=1,
                                                    key="b"),
                                           MenuItem("Quit", self.quit)])

        def test_call(self, item):
            print("testCall: ", item)
            item.text = "123"

        def remove(self, item):
            menu = [MenuItem("Add",
                             self.add,
                             data=1,
                             key="a"),
                    MenuItem("Remove",
                             self.remove,
                             data=1,
                             key="r"),
                    MenuItem("Quit", self.quit)]
            self.set_menu(menu)

        def add(self, item):
            print("add", item.data)
            item = MenuItem("Test", None, children=[
                MenuItem("Test1", self.test_call, data=1),
                None,
                MenuItem("Test2", self.test_call, data=2),
                MenuItem("Test3", self.test_call, data=3),
            ])
            self.append_menu_item_after("Add", item)

        def quit(self, _):
            super(DemoApp, self).quit(_)

    DemoApp().start()
