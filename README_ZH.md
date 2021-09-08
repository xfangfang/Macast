<img align="center" src="macast_slogan.png" alt="slogan" height="auto"/>

# Macast

[![visitor](https://visitor-badge.glitch.me/badge?page_id=xfangfang.Macast)](https://github.com/xfangfang/Macast/releases/latest)
[![stars](https://img.shields.io/badge/dynamic/json?label=github%20stars&query=stargazers_count&url=https%3A%2F%2Fapi.github.com%2Frepos%2Fxfangfang%2FMacast)](https://github.com/xfangfang/Macast)
[![build](https://img.shields.io/github/workflow/status/xfangfang/Macast/Build%20Macast)](https://github.com/xfangfang/Macast/actions/workflows/build-macast.yaml)
[![mac](https://img.shields.io/badge/MacOS-10.15%20and%20higher-lightgrey?logo=Apple)](https://github.com/xfangfang/Macast/releases/latest)
[![windows](https://img.shields.io/badge/Windows-10-lightgrey?logo=Windows)](https://github.com/xfangfang/Macast/releases/latest)
[![linux](https://img.shields.io/badge/Linux-Xorg-lightgrey?logo=Linux)](https://github.com/xfangfang/Macast/releases/latest)

[README_EN](README.md)

Macast是一个跨平台的 **菜单栏\状态栏** 应用，用户可以使用电脑接收发送自手机的视频、图片和音乐。支持主流视频音乐软件和其他任何符合DLNA协议的投屏软件.


## 安装

进入页面选择对应的操作系统下载即可，应用使用方法及截图见下方。

- ### MacOS || Windows || Debian

  下载地址1:  [Macast 最新正式版 github下载](https://github.com/xfangfang/Macast/releases/latest)

  下载地址2:  [Macast 最新正式版 gitee下载（推荐国内用户使用此链接）](https://gitee.com/xfangfang/Macast/releases/)

- ### 包管理

  ```shell
  # 需要 python>=3.6
  pip install git+https://github.com/xfangfang/Macast.git@dev
  ```

  请查看我们的wiki页面获取更多的信息（如aur支持）: [Macast/wiki/Installation#package-manager](https://github.com/xfangfang/Macast/wiki/Installation#package-manager)

- ### 从源码构建

  请参阅: [Macast Development](docs/Development.md)


*推荐linux用户和出现问题的用户（比如闪退、无法搜索到设备）从Github-Actions下载测试版本安装（需要登录github账号）：https://github.com/xfangfang/Macast/actions*
*尤其是linux用户，强烈推荐下载测试版，或从包管理器安装*


## 使用方法

- **普通用户**  
打开应用后，**菜单栏\状态栏** 会出现一个图标，这时你的设备就可以接收来自同一局域网的DLNA投放了。

- **进阶用户**  
通过加载 [Macast插件](https://github.com/xfangfang/Macast-plugins), Macast可以支持调用其他第三方应用，如：IINA、PotPlayer等等.  
更多信息请见: [Macast/wiki/FAQ#how-to-use-third-party-player-plug-in](https://github.com/xfangfang/Macast/wiki/FAQ#how-to-use-third-party-player-plug-in)

- **程序员**  
Macast使用MPV作为默认的播放器，很多朋友反馈说可不可以支持其他的播放器，比如Mac上的IINA或者是Windows上的PotPlayer。  
在小小的重构过之后，目前通过pip安装macast包，然后再依照教程完成自己的脚本，就可以快速的适配到你喜欢的播放器了，教程和一些示例代码在：[Macast/wiki/Custom-Renderer](https://github.com/xfangfang/Macast/wiki/Custom-Renderer)  
欢迎大家适配更多的播放器，提交代码到macast_renderer，在拥有了更多的播放器支持之后，准备在前端做一个自定义播放器选择的菜单项，提前感谢大家了。


## 开发计划

- [x] 完成第一版应用，支持MacOS
- [x] 添加对Linux和Windows的支持
- [x] 完善协议，增强软件适配性
- [x] 统一MacOS与其他平台的UI
- [ ] 添加多播放器支持
- [ ] 改进目前的播放器控制页面
- [ ] 添加bilibili弹幕投屏
- [ ] 支持airplay

## 常见问题与解决办法

0. Macast使用的端口号（端口1900）与其他软件冲突，体现为无法搜索到设备(常见于windows)

    关闭本机其他投屏搜索软件，可通过命令行排查，参考：[Macast/issues/19](https://github.com/xfangfang/Macast/issues/19#issuecomment-903573402)

1. Macast使用的端口号（端口1068）与其他软件冲突，体现为应用闪退

    尝试下载测试版, 测试版针对此情况会动态修改端口号：https://github.com/xfangfang/Macast/actions

2. Macast被电脑防火墙拦截

    手机尝试访问 http://电脑ip:1068，如:192.168.1.123:1068 如果出现helloworld 等字样排除问题
    *具体端口号见应用菜单设置的第一项，如果没有则为默认的1068*

3. 路由器问题

    路由器开启UPnP，关闭ap隔离，确认固件正常（部分openwrt有可能有问题）

4. 手机软件有问题，体现为无法搜索到设备

    可以重启软件或更换软件尝试，或向其他投屏接收端电视测试
    尝试在搜索页面等待久一点（最多1分钟如果搜不到那应该就是别的问题了）
    如操作系统为IOS，注意要开启软件的**本地网络发现**权限
    
5. 网络问题

    请确定手机和电脑处在同一网段下，比如说：电脑连接光猫的网线，手机连接路由器wifi，这种情况大概率是不在同一网段的，可以查看手机和电脑的ip前缀是否相同。

6. 其他未知问题

    尝试在同一局域网手机投电视，如果可以正常投说明问题还是出在电脑端，继续检查电脑问题或查看如何报告bug
    有用户反馈说搜索不到有可能是网卡的优先级问题，这个目前要确保连接到和手机同一局域网的网卡优先级最高，未来会修复这个问题。


## 报告bug

1. 你的电脑系统类型和版本：如Win10 20h2
2. 你使用的手机系统和软件：如 安卓 bilibili
3. bug复现：如何复现bug与bug是否可以稳定复现
4. 程序运行的log：
  - windows下载debug版应用：https://github.com/xfangfang/Macast/releases/latest
  - mac 终端输入：/Applications/Macast.app/Contents/MacOS/Macast 回车运行
  - linux 安装deb后，命令行运行macast或者直接从源码运行
5. 推荐github报告问题，issues区点击 **new issue** 会有详细的指引

## 用户反馈

解决问题的优先级：github\gitee > qq群 > bilibili评论区

⚠️ **因为希望这个应用晋升国际化全球知名😂，所以还是请尽量使用英语在github交流**

点击链接加入群聊【小方的软件工地】：[983730955](https://jq.qq.com/?_wv=1027&k=4ioK8gQs)

当然也可以考虑捐赠 ~~获得贵宾售后服务（开玩笑）~~ 支持Macast和他的开发者们为了这个软件熬过的日日夜夜

<img align="center" width="400" src="sponsorships.png" alt="sponsorships" height="auto"/>

<img align="center" width="400" src="https://service-65diwogz-1252652631.bj.apigw.tencentcs.com/release/sponsor.svg" alt="sponsors" height="auto"/>

## 使用截图
*如果系统设置为中文，Macast会自动切换中文界面*  

在投放视频或其他媒体文件后，可以点击应用图标复制媒体下载链接  
<img align="center" width="400" src="https://github.com/xfangfang/xfangfang.github.io/raw/master/assets/img/macast/copy_uri.png" alt="copy_uri" height="auto"/>

支持选择第三方播放器 (目前只有[测试版](https://github.com/xfangfang/Macast/actions)可用)  
<img align="center" width="400" src="https://github.com/xfangfang/xfangfang.github.io/raw/master/assets/img/macast/select_renderer.png" alt="select_renderer" height="auto"/>


## 相关链接

[UPnP™ Device Architecture 1.1](http://upnp.org/specs/arch/UPnP-arch-DeviceArchitecture-v1.1.pdf)

[UPnP™ Resources](http://upnp.org/resources/upnpresources.zip)

[UPnP™ ContentDirectory:1 service](http://upnp.org/specs/av/UPnP-av-ContentDirectory-v1-Service.pdf)

[UPnP™ MediaRenderer:1 device](http://upnp.org/specs/av/UPnP-av-MediaRenderer-v1-Device.pdf)

[UPnP™ AVTransport:1 service](http://upnp.org/specs/av/UPnP-av-AVTransport-v1-Service.pdf)

[UPnP™ RenderingControl:1 service](http://upnp.org/specs/av/UPnP-av-RenderingControl-v1-Service.pdf)

[python-upnp-ssdp-example](https://github.com/ZeWaren/python-upnp-ssdp-example)
