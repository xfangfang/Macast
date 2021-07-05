# Macast

[Chinese README](https://github.com/xfangfang/Macast/blob/main/README_ZH.md)

<img align="right" src="https://raw.githubusercontent.com/xfangfang/Macast/main/demo.png?raw=true" alt="demo" width="256" height="auto"/> A menu bar application using mpv as **DLNA AVTransport Media Renderer**.

Currently supported platform 🖥 :

- [x] MacOS
- [x] Gnome (test with ubuntu20.04)
- [x] KDE (test with kubuntu21.04)
- [x] Other Linux under xorg (test with Raspberry Pi OS)
- [x] Windows (beta)

For details of GUI support, please refer to: https://pystray.readthedocs.io/en/latest/usage.html#selecting-a-backend

## Install

- ### MacOS

Download link:  [Macast_v*_darwin.zip](https://github.com/xfangfang/Macast/releases/latest)

- ### Windows

Download link:  [Macast_v*_windows_debug.zip](https://github.com/xfangfang/Macast/releases/latest)

- ### Linux

```
wget https://github.com/xfangfang/Macast/archive/main.zip
unzip main.zip
cd Macast-main
pip3 install pystray cherrypy lxml requests
python3 Macast.py
# if there is something wrong, try this:
export PYSTRAY_BACKEND=gtk && python3 Macast.py
```

Tips:
1. Make sure you have **mpv** installed:

```
# install mpv in ubuntu
sudo apt install mpv
```

2. Make sure you can use **gi**:

```
$ python3
Python 3.7.10 (default, Jun  3 2021, 17:51:26)
Type "help", "copyright", "credits" or "license" for more information.
>>> import gi
>>>
```

if there is something wrong, try: **sudo apt-get install python3-gi**

if you use conda, check this https://stackoverflow.com/a/40303128


## Usage

After opening this app, a small icon will appear in the menu bar, and you can push video from a local DLNA client.


## Development upder MacOS

### 1. download mpv

```shell
wget https://laboratory.stolendata.net/~djinn/mpv_osx/mpv-latest.tar.gz
mkdir -p bin && tar --strip-components 2 -C bin -xzvf mpv-latest.tar.gz mpv.app/Contents/MacOS
```

### 2. debug

```shell
pip install -r requirements/darwin.txt
python Macast.py
```
`⚠️ MPV starts slowly the first time you run Macast.py, it needs to wait for a while`

### 3. package

```shell
pip install py2app
pip install setuptools==44.0.0 # try this if you cannot run Macast.app
python setup.py py2app
cp -R bin dist/Macast.app/Contents/Resources/
open dist
```

`⚠️ After packing, you can find the compiled content in the dist directory`


## Development under Windows

### 1. download mpv

```powershell
$client = new-object System.Net.WebClient
$client.DownloadFile('https://nchc.dl.sourceforge.net/project/mpv-player-windows/stable/mpv-0.33.0-x86_64.7z','mpv.7z')
7z x -obin mpv.7z *.exe
```

### 2. debug

```powershell
pip install -r requirements/common.txt
python Macast.py
```

### 3. package

```powershell
pip install pyinstaller
pyinstaller --noconfirm -F -w --additional-hooks-dir=. --add-data=".version;." --add-data="macast/xml/*;macast/xml"  --add-data="i18n/zh_CN/LC_MESSAGES/*.mo;i18n/zh_CN/LC_MESSAGES" --add-data="assets/*;assets" --add-binary="bin/mpv.exe;bin" --icon=assets/icon.ico Macast.py
```


## Relevant links

[UPnP™ Device Architecture 1.1](http://upnp.org/specs/arch/UPnP-arch-DeviceArchitecture-v1.1.pdf)

[python-upnp-ssdp-example](https://github.com/ZeWaren/python-upnp-ssdp-example)

[pystray](https://github.com/moses-palmer/pystray)
