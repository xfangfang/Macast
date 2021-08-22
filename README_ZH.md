<img align="center" src="macast_slogan.png" alt="slogan" height="auto"/>

# Macast

[![visitor](https://visitor-badge.glitch.me/badge?page_id=xfangfang.Macast)](https://github.com/xfangfang/Macast/releases/latest)
[![build](https://img.shields.io/github/workflow/status/xfangfang/Macast/Build%20Macast)](https://github.com/xfangfang/Macast/actions/workflows/build-macast.yaml)
[![mac](https://img.shields.io/badge/MacOS-10.15%20and%20higher-lightgrey?logo=Apple)](https://github.com/xfangfang/Macast/releases/latest)
[![windows](https://img.shields.io/badge/Windows-10-lightgrey?logo=Windows)](https://github.com/xfangfang/Macast/releases/latest)
[![linux](https://img.shields.io/badge/Linux-Xorg-lightgrey?logo=Linux)](https://github.com/xfangfang/Macast/releases/latest)

[README_EN](README.md)

Macast是一个跨平台的 **菜单栏\状态栏** 应用，用户可以使用电脑接收发送自手机的视频、图片和音乐。支持主流视频音乐软件和其他任何符合DLNA协议的投屏软件.


## 安装

进入页面选择对应的操作系统下载即可。

- ### MacOS || Windows || Debian

下载地址:  [Macast 最新发布](https://gitee.com/xfangfang/Macast/releases/)

- ### 从源码构建

请参阅: [Macast Development](docs/Development.md)


## 使用方法

打开应用后，**菜单栏\状态栏** 会出现一个图标，这时你的设备就可以接收来自同一局域网的DLNA投放了。

## 常见问题与解决办法

1. Macast使用的端口号与其他软件冲突

    尝试重启电脑，一开机就打开Macast（注意双击一次就可以别开多了）

2. Macast被电脑防火墙拦截

    手机尝试访问 http://电脑ip:1068，如:192.168.1.123:1068 如果出现helloworld 等字样排除问题

3. 路由器问题

    路由器开启UPnP，关闭ap隔离，确认固件正常（部分openwrt有可能有问题）

4. 手机软件有问题

    可以重启软件或更换软件尝试，或向其他投屏接收端电视测试

5. 其他未知问题

    尝试在同一局域网手机投电视，如果可以正常投说明问题还是出在电脑端，继续检查电脑问题或查看如何报告bug


## 报告bug

1. 你的电脑系统类型和版本：如Win10 20h2
2. 你使用的手机系统和软件：如 安卓 bilibili
3. bug复现：如何复现bug与bug是否可以稳定复现
4. 程序运行的log：
  - windows下载debug版应用：https://github.com/xfangfang/Macast/releases/download/v0.5/Macast-v0.5-debug.exe
  - mac 终端输入：/Applications/Macast.app/Contents/MacOS/Macast 回车运行
  - linux 安装deb后，命令行运行macast或者直接从源码运行
5. 推荐github报告问题，issues区点击 **new issue** 会有详细的指引

## 用户反馈

解决问题的优先级：github\gitee > qq群 > bilibili评论区

⚠️ **因为希望这个应用晋升国际化全球知名😂，所以还是请尽量使用英语在github交流**

点击链接加入群聊【小方的软件工地】：[983730955](https://jq.qq.com/?_wv=1027&k=4ioK8gQs)

当然也可以考虑捐赠 ~~获得贵宾售后服务（开玩笑）~~ 支持Macast和他的开发者们为了这个软件熬过的日日夜夜

<img align="center" width="256" src="sponsorships.png" alt="sponsorships" height="auto"/>

## 相关链接

[UPnP™ Device Architecture 1.1](http://upnp.org/specs/arch/UPnP-arch-DeviceArchitecture-v1.1.pdf)

[UPnP™ Resources](http://upnp.org/resources/upnpresources.zip)

[UPnP™ ContentDirectory:1 service](http://upnp.org/specs/av/UPnP-av-ContentDirectory-v1-Service.pdf)

[UPnP™ MediaRenderer:1 device](http://upnp.org/specs/av/UPnP-av-MediaRenderer-v1-Device.pdf)

[UPnP™ AVTransport:1 service](http://upnp.org/specs/av/UPnP-av-AVTransport-v1-Service.pdf)

[UPnP™ RenderingControl:1 service](http://upnp.org/specs/av/UPnP-av-RenderingControl-v1-Service.pdf)

[python-upnp-ssdp-example](https://github.com/ZeWaren/python-upnp-ssdp-example)
