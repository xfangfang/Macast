# Copyright (c) 2021 by xfangfang. All Rights Reserved.

import sys
import logging
import webbrowser
import subprocess
import threading
from abc import abstractmethod
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


class MenuItem():
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


class App():
    def __init__(self, name, icon, menu, template=True):
        self.name = name
        self.icon = icon
        self.app = None
        self.menu = menu
        self.menuDict = {}
        self.template = template
        if sys.platform == 'darwin':
            self.platform = Platform.Darwin
            self.initPlatformDarwin()
        elif sys.platform == 'win32':
            self.platform = Platform.Win32
            self.initPlatformWin32()
        else:
            self.platform = Platform.Others
            self.initPlatformOthers()

        if self.platform == Platform.Darwin:
            self.app = rumps.App(self.name,
                                 icon=self.icon,
                                 menu=self._buildMenuRumps(self.menu),
                                 template=self.template,
                                 quit_button=None)
            rumps.debug_mode(True)
        else:
            self.app = pystray.Icon(self.name,
                                    Image.open(self.icon),
                                    menu=pystray.Menu(
                                        lambda:
                                            self._buildMenuPystray(self.menu)))

    def initPlatformDarwin(self):
        pass

    def initPlatformWin32(self):
        pass

    def initPlatformOthers(self):
        pass

    def _buildMenuRumps(self, menu):
        items = []
        for item in menu:
            if item is None:
                items.append(None)
            elif item.children is not None:
                menuItem = rumps.MenuItem(item.text)
                items.append([menuItem, self._buildMenuRumps(item.children)])
            else:
                items.append(self._buildMenuItemRumps(item))
        return items

    def _buildMenuItemRumps(self, item):
        callback = item._rumpsCallback if item.enabled else None
        menuItem = rumps.MenuItem(item.text,
                                  callback,
                                  item.key)
        menuItem.state = 1 if item.checked else 0
        item.view = menuItem
        return menuItem

    def _buildMenuPystray(self, menu):
        items = []
        for item in menu:
            if item is None:
                items.append(pystray.Menu.SEPARATOR)
            elif item.children is not None and len(item.children) > 0:
                menuItem = pystray.MenuItem(
                    item.text, pystray.Menu(
                        *self._buildMenuPystray(item.children)))
                items.append(menuItem)
            else:
                menuItem = pystray.MenuItem(lambda i: i.view.text,
                                            item._pystrayCallback,
                                            lambda i: True if i.view.checked
                                            else None,
                                            enabled=lambda i: i.view.enabled)
                item.view = menuItem
                menuItem.view = item
                items.append(menuItem)
        return items

    def updateIcon(self, icon, template=True):
        self.icon = icon
        if self.platform == Platform.Darwin:
            self.app.template = template
            self.app.icon = self.icon
        else:
            self.app.icon = Image.open(self.icon)

    def _findMenuItemIndexByID(self, id):
        #  TODO find all items
        for i, item in enumerate(self.menu):
            if item.id is not None and item.id == id:
                return i
        logger.error("Canot find id:{}.".format(id))
        return -1

    def appendMenuItemAfter(self, id, menuItem):
        if self.platform == Platform.Darwin:
            self.app.menu.insert_after(id, self._buildMenuItemRumps(menuItem))
        else:
            index = self._findMenuItemIndexByID(id)
            print("index: ", index)
            if index != -1:
                self.menu.insert(index + 1, menuItem)
                self.app.update_menu()

    def appendMenuItemBefore(self, id, menuItem):
        if self.platform == Platform.Darwin:
            self.app.menu.insert_before(id, self._buildMenuItemRumps(menuItem))
        else:
            index = self._findMenuItemIndexByID(id)
            if index != -1:
                self.menu.insert(index, menuItem)
                self.app.update_menu()

    def removeMenuItemByID(self, id):
        if self.platform == Platform.Darwin:
            self.app.menu.pop(id)
        else:
            index = self._findMenuItemIndexByID(id)
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
                res = Setting.systemShell(
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

    def openBrowser(self, url):
        if self.platform == Platform.Darwin:
            subprocess.Popen(['open', url])
        elif self.platform == Platform.Win32:
            webbrowser.open(url)
        else:
            try:
                subprocess.Popen("sensible-browser {}".format(url),
                                 shell=True,
                                 env=Setting.getSystemEnv())
            except Exception as e:
                logger.error(e)
                webbrowser.open(url)


if __name__ == '__main__':
    class DemoApp(App):
        def __init__(self):
            super(DemoApp, self).__init__("Macast",
                                          "assets/menu_light.png",
                                          [MenuItem("Add",
                                                    self.add,
                                                    data=1,
                                                    key="a"),
                                           MenuItem("Quit", self.quit)])

        def testCall(self, item):
            print("testCall: ", item)
            item.text = "123"

        def add(self, item):
            print("add", item.data)
            item = MenuItem("Test", None, children=[
                MenuItem("Test1", self.testCall, data=1),
                None,
                MenuItem("Test2", self.testCall, data=2),
                MenuItem("Test3", self.testCall, data=3),
            ])
            self.appendMenuItemAfter("Add", item)

        def quit(self, _):
            super(DemoApp, self).quit(_)

    DemoApp().start()
