# Copyright (c) 2021 by xfangfang. All Rights Reserved.

import os
import re
import json
import logging
import macast
import gettext
import requests
import threading
import subprocess
from abc import abstractmethod

logger = logging.getLogger("Macast ")
logger.setLevel(logging.DEBUG)

try:
    locale = macast.Setting.getLocale()
    lang = gettext.translation('macast', localedir='i18n', languages=[locale])
    lang.install()
    logger.error("Macast_darwin Loading Language: {}".format(locale))
except Exception as e:
    _ = gettext.gettext
    logger.error("Macast_darwin Loading Default Language en_US")


class Macast(object):
    def init(self):
        self.thread = None
        self.running = False
        self.startCast()
        threading.Thread(target = self.checkUpdate, kwargs={'verbose': False}).start()
        logger.debug("Macast APP started")

    @abstractmethod
    def alert(self, content):
        pass

    @abstractmethod
    def notification(self, title, content):
        pass

    @abstractmethod
    def openBrowser(self, url):
        pass

    def about(self):
        self.openBrowser('https://github.com/xfangfang/Macast')

    def stopCast(self):
        macast.stop()
        self.thread.join()
        self.running = False

    def startCast(self):
        if self.running:
            return
        self.thread = threading.Thread(target=macast.run, args=())
        self.thread.start()
        self.running = True

    def checkUpdate(self, verbose = True):
        try:
            res = requests.get('https://api.github.com/repos/xfangfang/Macast/releases/latest').text
            res = json.loads(res)
            logger.debug("tag_name: {}".format(res['tag_name']))
            onlineVersion = re.findall(r'(\d+\.*\d+)', res['tag_name'])[0]
            if float(macast.Setting.getVersion()) < float(onlineVersion):
                self.notification(_("New Update {}").format(res['tag_name']), "opening browser")
                self.openBrowser('https://github.com/xfangfang/Macast/releases/latest')
            else:
                if verbose:
                    self.alert(_("You're up to date."))
        except Exception as e:
            logger.error("get update info error: {}".format(e))

    def toggle(self):
        if self.running:
            self.stopCast()
        else:
            self.startCast()

    def quit(self):
        if self.running:
            self.stopCast()

if macast.Setting.getSystem() == 'Darwin':
    import rumps
    class Macast_darwin(rumps.App, Macast):
        def __init__(self):
            super(Macast_darwin, self).__init__("Macast",icon='assets/menu.png', title="", template=True, quit_button=None)
            macast.Setting.setMpvPath(os.path.abspath('bin/MacOS/mpv'))
            self.init()
            self.menu = [
                rumps.MenuItem(_("Pause"), callback=self.toggle),
                None,
                [
                    rumps.MenuItem(_("Setting")),
                    [
                        rumps.MenuItem("IP: {}".format(macast.Setting.getIP())),
                        rumps.MenuItem("Macast (v{})".format(macast.Setting.getVersion())),
                        rumps.MenuItem(_("Check for updates"), callback=self.check),
                        rumps.MenuItem(_("About"), callback=self.about),
                    ]
                ],
                rumps.MenuItem(_("Quit"), callback=self.quit),
            ]
            rumps.debug_mode(True)

        def toggle(self, sender):
            super(Macast_darwin, self).toggle()
            if self.running:
                sender.title = _('Pause')
            else:
                sender.title = _('Start')


        def openBrowser(self, url):
            subprocess.run(['open', url])

        def alert(self, content):
            rumps.alert(content)

        def notification(self, title, content):
            rumps.notification(title, "", content)

        def check(self, _):
            self.checkUpdate()

        def about(self, _):
            super(Macast_darwin, self).about()

        def quit(self, _):
            super(Macast_darwin, self).quit()
            rumps.quit_application()

else:
    import pystray
    import webbrowser
    from PIL import Image
    class Macast_common(Macast):
        def __init__(self):
            super(Macast_common, self).__init__()
            if macast.Setting.getSystem() == 'Windows':
                macast.Setting.setMpvPath(os.path.abspath('bin/mpv.exe'))
            self.init()
            self.icon = pystray.Icon('Macast', Image.open('assets/menu.png'), menu = pystray.Menu(
                    pystray.MenuItem("IP: {}".format(macast.Setting.getIP()), None, enabled=False),
                    pystray.MenuItem("Macast (v{})".format(macast.Setting.getVersion()), None, enabled=False),
                    pystray.MenuItem(_("Check for updates"), self.check),
                    pystray.MenuItem(_("About"), self.about),
                    pystray.MenuItem(_('Quit'), self.quit),
                )
            )

        def openBrowser(self, url):
            webbrowser.open(url)

        def alert(self, content):
            self.icon.notify(message=content, title="Macast")

        def notification(self, title, content):
            self.icon.notify(message=content, title=title)

        def check(self, icon, item):
            self.checkUpdate()

        def about(self, icon, item):
            super(Macast_common, self).about()

        def quit(self, icon, item):
            icon.remove_notification()
            super(Macast_common, self).quit()
            self.icon.stop()

        def run(self):
            self.icon.run()

if __name__ == '__main__':
    if macast.Setting.getSystem() == 'Darwin':
        Macast_darwin().run()
    else:
        Macast_common().run()
