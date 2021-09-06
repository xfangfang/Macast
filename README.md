<img align="center" src="macast_slogan.png" alt="slogan" height="auto"/>

# Macast

[![visitor](https://visitor-badge.glitch.me/badge?page_id=xfangfang.Macast)](https://github.com/xfangfang/Macast/releases/latest)
[![downloads](https://img.shields.io/github/downloads/xfangfang/Macast/total?color=blue)](https://github.com/xfangfang/Macast/releases/latest)
[![build](https://img.shields.io/github/workflow/status/xfangfang/Macast/Build%20Macast)](https://github.com/xfangfang/Macast/actions/workflows/build-macast.yaml)
[![mac](https://img.shields.io/badge/MacOS-10.15%20and%20higher-lightgrey?logo=Apple)](https://github.com/xfangfang/Macast/releases/latest)
[![windows](https://img.shields.io/badge/Windows-10-lightgrey?logo=Windows)](https://github.com/xfangfang/Macast/releases/latest)
[![linux](https://img.shields.io/badge/Linux-Xorg-lightgrey?logo=Linux)](https://github.com/xfangfang/Macast/releases/latest)

[中文说明](README_ZH.md)

A menu bar application using mpv as **DLNA Media Renderer**. You can push videos, pictures or musics from your mobile phone to your computer.


## Installation

- ### MacOS || Windows || Debian

  Download link:  [Macast release latest](https://github.com/xfangfang/Macast/releases/latest)

- ### Package manager

  ```shell
  pip install git+https://github.com/xfangfang/Macast.git@dev
  ```

  Please see our wiki for more information: [Macast/wiki/Installation#package-manager](https://github.com/xfangfang/Macast/wiki/Installation#package-manager)

- ### Build from source

  Please refer to: [Macast Development](docs/Development.md)


## Usage

- **For ordinary users**  
After opening this app, a small icon will appear in the menu bar, then you can push your media files from a local DLNA client to your computer.

- **For developer**  
Macast uses MPV as the default video player. After installing macast through pip, you can use a few lines of code to add support for other players like IINA and PotPlayer.  
Tutorials and examples are shown in: [Macast/wiki/Custom-Renderer](https://github.com/xfangfang/Macast/wiki/Custom-Renderer)  
Fell free to submit a pull request that creates support for any of the video players not yet supported. 

## FAQ
If you have any questions about this application, please check: [Macast/wiki/FAQ](https://github.com/xfangfang/Macast/wiki/FAQ).  
If this does not solve your problem, please open a new issue to notify us, we are willing to help you solve the problem.


## Relevant links

[UPnP™ Device Architecture 1.1](http://upnp.org/specs/arch/UPnP-arch-DeviceArchitecture-v1.1.pdf)

[UPnP™ Resources](http://upnp.org/resources/upnpresources.zip)

[UPnP™ ContentDirectory:1 service](http://upnp.org/specs/av/UPnP-av-ContentDirectory-v1-Service.pdf)

[UPnP™ MediaRenderer:1 device](http://upnp.org/specs/av/UPnP-av-MediaRenderer-v1-Device.pdf)

[UPnP™ AVTransport:1 service](http://upnp.org/specs/av/UPnP-av-AVTransport-v1-Service.pdf)

[UPnP™ RenderingControl:1 service](http://upnp.org/specs/av/UPnP-av-RenderingControl-v1-Service.pdf)

[python-upnp-ssdp-example](https://github.com/ZeWaren/python-upnp-ssdp-example)
