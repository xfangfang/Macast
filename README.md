# dlna-media-render

[Chinese README](https://github.com/xfangfang/Macast/blob/main/README_ZH.md)

using mpv as DLNA media render runing on MacOS

![demo](demo.png)

## Install

Download link:  [Macast](https://github.com/xfangfang/Macast/releases/latest)


## usage

After opening this app, a small TV icon will appear in the status bar, and you can  push video from DLNA client from the same LAN to your computer.

`⚠️ The "~/Library/Application\ Support/Macast" directory will be created to save the configuration information of the application`


## development

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
