# Copyright (c) 2021 by xfangfang. All Rights Reserved.

import sys
import logging
import subprocess
import cherrypy
from enum import Enum
from .utils import Setting, format_class_name
from typing import Callable, List

if sys.platform == 'darwin':
    import rumps
else:
    import pystray
    import webbrowser
    from PIL import Image

logger = logging.getLogger("GUI")


class Platform(Enum):
    Darwin = 0
    Win32 = 1
    Others = 2


class MenuItem:
    def __init__(self, text, callback=None, checked=None, enabled=True,
                 children=None, data=None, key=None):
        """
        :param text: the text shows on this menu item
        :param callback: the function serving as callback for when a click event occurs on this menu item
        :param checked: True if you want show a check mark on this menu item
        :param enabled: Literally
        :param children: a list of MenuItem, if it is not empty, callback will not be called
        :param data: set additional data to this menu item, it can be obtained through callback
        :param key: the key shortcut to click this menu item
        """
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

        logger.log(1, f'Create MenuItem: {text} with data: {data}')

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
        """ Decoration of pystray callback function
        :param app: pystray app instance
        :param item: pystray menu item instance
        :return:
        """
        logger.debug(f'Click menu item: {self.text} with data: {self.data}')
        self.callback(self)

    def _rumpsCallback(self, item):
        """ Decoration of rumps callback function
        :param item: rumps menu item instance
        :return:
        """
        logger.debug(f'Click menu item: {self.text} with data: {self.data}')
        self.callback(self)


class App:
    def __init__(self, name: str, icon: str, menu: [MenuItem], template=True):
        """

        :param name: App name
        :param icon: Menubar icon
        :param menu: a list of MenuItem, see the DemoApp at the end of this file for example
        :param template: If true, the icon color will be switched according to the system theme color, Macos only.
        """
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

        cherrypy.engine.subscribe('get_macast_app', lambda: self)

    def init_platform_darwin(self):
        pass

    def init_platform_win32(self):
        pass

    def init_platform_others(self):
        pass

    def _build_menu_rumps(self, menu: [MenuItem]):
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

    def _build_menu_item_rumps(self, item: MenuItem):
        callback = item._rumpsCallback if item.enabled else None
        menu_item = rumps.MenuItem(item.text, callback, item.key)
        menu_item.state = 1 if item.checked else 0
        item.view = menu_item
        # rumps using `text` as key to find a menu item
        item.id = item.text
        return menu_item

    def _build_menu_pystray(self, menu: [MenuItem]):
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

    def update_icon(self, icon: str, template=True):
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

    def set_menu(self, menu: [MenuItem]):
        self.menu = menu
        if self.platform == Platform.Darwin:
            self.app.menu.clear()
            self.app.menu = self._build_menu_rumps(menu)
        else:
            self.app.menu = pystray.Menu(lambda: self._build_menu_pystray(menu))

    def _find_menu_item_index_by_id(self, item_id: str):
        """
        This method is only for linux and windows
        :param item_id:
        :return:
        """
        #  TODO find all items
        for i, item in enumerate(self.menu):
            if item.id is not None and item.id == item_id:
                return i
        logger.error("Canot find id:{}.".format(item_id))
        return -1

    def append_menu_item_after(self, item_id: str, menu_item: MenuItem):
        if self.platform == Platform.Darwin:
            self.app.menu.insert_after(item_id, self._build_menu_item_rumps(menu_item))
        else:
            index = self._find_menu_item_index_by_id(item_id)
            if index != -1:
                self.menu.insert(index + 1, menu_item)
                self.app.update_menu()

    def append_menu_item_before(self, item_id: str, menu_item: MenuItem):
        if self.platform == Platform.Darwin:
            self.app.menu.insert_before(item_id, self._build_menu_item_rumps(menu_item))
        else:
            index = self._find_menu_item_index_by_id(item_id)
            if index != -1:
                self.menu.insert(index, menu_item)
                self.app.update_menu()

    def remove_menu_item_by_id(self, item_id: str):
        if self.platform == Platform.Darwin:
            if item_id in self.app.menu:
                self.app.menu.pop(item_id)
        else:
            index = self._find_menu_item_index_by_id(item_id)
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

    def alert(self, content: str):
        if sys.platform == 'darwin':
            rumps.alert(content)
        else:
            self.notification(content, "Macast")

    def notification(self, title: str, content: str, sound=True):
        if sys.platform == 'darwin':
            rumps.notification(title, "", content, sound=sound)
        else:
            try:
                self.app.notify(message=content, title=title)
            except NotImplementedError as e:
                pass

    def dialog(self, content: str, callback=None, cancel="Cancel", ok="Ok"):
        if sys.platform == 'darwin':
            try:
                res = Setting.system_shell(
                    ['osascript',
                     '-e',
                     f'display dialog "{content}" '
                     f'with icon POSIX file "{Setting.get_base_path("assets/icon.icns")}"'
                     f'with title "Macast" buttons {{"{cancel}","{ok}"}}'
                     ])
                if ok in res[1] and callback:
                    callback()
            except Exception as e:
                self.notification("Error", "Cannot access System Events")
                logger.error(f"Cannot access System Events: {e}")
                callback()
        else:
            self.notification("Macast", content)
            if callable(callback):
                callback()

    @staticmethod
    def get_env():
        """
        The program packaged with pyinstaller on Linux can't read system variables correctly,
        so it can't run programs such as xdg-open.
        You can get the correct environment variables by using this method
        :return: env in dict
        """
        # https://github.com/pyinstaller/pyinstaller/issues/3668#issuecomment-742547785
        env = Setting.get_system_env()
        toDelete = []
        for (k, v) in env.items():
            if k != 'PATH' and 'tmp' in v:
                toDelete.append(k)
        for k in toDelete:
            env.pop(k, None)
        return env

    def open_browser(self, url: str):
        """
        Open a website using the default browser
        :param url:
        :return:
        """
        if self.platform == Platform.Darwin:
            subprocess.Popen(['open', url])
        elif self.platform == Platform.Win32:
            webbrowser.open_new(url)
        else:
            subprocess.Popen(["xdg-open", url], env=App.get_env())

    def open_directory(self, path: str):
        """
        Open a local folder
        :param path: directory path
        :return:
        """
        if self.platform == Platform.Darwin:
            subprocess.Popen(['open', path])
        elif self.platform == Platform.Win32:
            subprocess.Popen(['explorer.exe', path])
        else:
            subprocess.Popen(["xdg-open", path], env=App.get_env())

    @staticmethod
    def build_menu_item_group(titles: [str], callback: Callable[[MenuItem], None]):
        items = []
        for index, title in enumerate(titles):
            item = MenuItem(title, callback, data=index)
            items.append(item)
        return items

    @staticmethod
    def build_menu_item_select(title: str,
                               sub_menu_titles: [str],
                               callback: Callable[[MenuItem], None],
                               selection) -> MenuItem:

        menuitem = MenuItem(title,
                            children=App.build_menu_item_group(
                                sub_menu_titles,
                                callback
                            ))
        if isinstance(selection, list):
            for i in menuitem.children:
                if i.text in selection:
                    i.checked = True
        else:
            for i in menuitem.children:
                if i.text == selection:
                    i.checked = True
                    break
            else:
                if len(menuitem.children) > 0:
                    menuitem.children[0].checked = True

        return menuitem


class Tool:

    def __init__(self):
        self._title = None

    @property
    def title(self):
        if self._title is not None:
            return self._title
        return format_class_name(self)

    def build_menu(self) -> List[MenuItem]:
        return []

    def build_menu_html(self):
        return []

    def start(self):
        logger.info(f"{self.title} Started")

    def stop(self):
        logger.info(f"{self.title} Stopped")


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
