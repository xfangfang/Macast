# Macast

[Chinese README](https://github.com/xfangfang/Macast/blob/main/README_ZH.md)

A menu bar application using mpv as DLNA media render runing on Linux under Xorg, GNOME, Ubuntu and MacOS

![demo](demo.png)

## Install

### MacOS

Download link:  [Macast_v*.zip](https://github.com/xfangfang/Macast/releases/latest)

### Linux under Xorg, GNOME and Ubuntu

```
wget https://github.com/xfangfang/Macast/archive/main.zip
unzip main.zip
cd Macast-main
pip install pystray cherrypy lxml requests
python3 Macast.py
```

Tips:
1. make sure you can use **mpv** in terminal
2. make sure you can use **gi**:

```
$ python3
Python 3.7.10 (default, Jun  3 2021, 17:51:26)
Type "help", "copyright", "credits" or "license" for more information.
>>> import gi
>>>
```

if there is something wrong, try: **sudo apt-get install python3-gi**

if you use conda, check this https://stackoverflow.com/a/40303128


## usage

After opening this app, a small icon will appear in the menu bar, and you can push video from a local DLNA client.

`⚠️ In MacOS The "~/Library/Application\ Support/Macast" directory will be created to save the configuration information of the application`


## development upder MacOS

### download mpv

```shell
wget https://laboratory.stolendata.net/~djinn/mpv_osx/mpv-latest.tar.gz
mkdir -p bin && tar --strip-components 2 -C bin -xzvf mpv-latest.tar.gz mpv.app/Contents/MacOS
```

### debug

```shell
pip install -r requirements.txt
python Macast.py
```
`⚠️ MPV starts slowly the first time you run Macast.py, it needs to wait for a while`

### package

```shell
pip install py2app
pip install setuptools==44.0.0 # try this if you cannot run Macast.app
python setup.py py2app
cp -R bin dist/Macast.app/Contents/Resources/
open dist
```

`⚠️ After packing, you can find the compiled content in the dist directory`


## Relevant links

[UPnP™ Device Architecture 1.1](http://upnp.org/specs/arch/UPnP-arch-DeviceArchitecture-v1.1.pdf)

[python-upnp-ssdp-example](https://github.com/ZeWaren/python-upnp-ssdp-example)
