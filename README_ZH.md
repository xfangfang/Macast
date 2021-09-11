<img align="center" src="macast_slogan.png" alt="slogan" height="auto"/>

# Macast

[![visitor](https://visitor-badge.glitch.me/badge?page_id=xfangfang.Macast)](https://github.com/xfangfang/Macast/releases/latest)
[![stars](https://img.shields.io/badge/dynamic/json?label=github%20stars&query=stargazers_count&url=https%3A%2F%2Fapi.github.com%2Frepos%2Fxfangfang%2FMacast)](https://github.com/xfangfang/Macast)
[![plugins](https://shields-staging.herokuapp.com/github/directory-file-count/xfangfang/Macast-plugins?type=dir&label=plugins)](https://github.com/xfangfang/Macast-plugins)
[![build](https://img.shields.io/github/workflow/status/xfangfang/Macast/Build%20Macast)](https://github.com/xfangfang/Macast/actions/workflows/build-macast.yaml)
[![mac](https://img.shields.io/badge/MacOS-10.15%20and%20higher-lightgrey?logo=Apple)](https://github.com/xfangfang/Macast/releases/latest)
[![windows](https://img.shields.io/badge/Windows-10-lightgrey?logo=Windows)](https://github.com/xfangfang/Macast/releases/latest)
[![linux](https://img.shields.io/badge/Linux-Xorg-lightgrey?logo=Linux)](https://github.com/xfangfang/Macast/releases/latest)

[README_EN](README.md)

Macast是一个跨平台的 **菜单栏\状态栏** 应用，用户可以使用电脑接收发送自手机的视频、图片和音乐，支持主流视频音乐软件和其他任何符合DLNA协议的投屏软件。

😂 **请尽量使用英语在Github交流，如果喜欢的话可以点个star关注后续更多协议支持的更新**



## 安装

进入页面选择对应的操作系统下载即可，应用使用方法及截图见下方。

- ### MacOS || Windows || Debian

  下载地址1:  [Macast 最新正式版 github下载](https://github.com/xfangfang/Macast/releases/latest)

  下载地址2:  [Macast 最新正式版 gitee下载（推荐国内用户使用此链接）](https://gitee.com/xfangfang/Macast/releases/)

- ### 包管理
  你也可以使用包管理器安装macast  
  ```shell
  # 需要 python>=3.6
  pip install macast
  ```

  请查看我们的wiki页面获取更多的信息（如aur支持）: [Macast/wiki/Installation#package-manager](https://github.com/xfangfang/Macast/wiki/Installation#package-manager)  
  Linux用户使用包管理器安装时运行可能会有问题，需要替换两个库为我修改过的库：

  ```shell
  pip install git+https://github.com/xfangfang/pystray.git
  pip install git+https://github.com/xfangfang/pyperclip.git
  ```

- ### 从源码构建

  请参阅: [Macast Development](docs/Development.md)


## 使用方法

- **普通用户**  
打开应用后，**菜单栏 \ 状态栏 \ 任务栏** 会出现一个图标，这时你的设备就可以接收来自同一局域网的DLNA投放了。

- **进阶用户**  
  1. 通过加载 [Macast插件](https://github.com/xfangfang/Macast-plugins), Macast可以支持调用其他第三方应用，如：IINA、PotPlayer等等.  
  更多信息请见: [Macast/wiki/FAQ#how-to-use-third-party-player-plug-in](https://github.com/xfangfang/Macast/wiki/FAQ#how-to-use-third-party-player-plug-in)  
  2. 你可以修改默认播放器的快捷键或其他参数，见：[#how-to-set-personal-configurations-to-mpv](https://github.com/xfangfang/Macast/wiki/FAQ#how-to-set-personal-configurations-to-mpv)

- **程序员**  
可以依照教程完成自己的脚本，快速的适配到你喜欢的播放器，或者增加一些新的功能插件，比如：边下边看，自动复制视频链接等等。教程和一些示例代码在：[Macast/wiki/Custom-Renderer](https://github.com/xfangfang/Macast/wiki/Custom-Renderer)  
欢迎大家适配更多的播放器，提交代码到[Macast插件](https://github.com/xfangfang/Macast-plugins)。


## 开发计划

- [x] 完成第一版应用，支持MacOS
- [x] 添加对Linux和Windows的支持
- [x] 完善协议，增强软件适配性
- [x] 统一MacOS与其他平台的UI
- [x] 添加多播放器支持
- [x] 添加多网卡支持
- [x] 添加自定义端口和自定义播放器名称
- [ ] 改进目前的播放器控制页面
- [ ] 添加bilibili弹幕投屏
- [ ] 支持airplay

## 出现问题的可能原因及解决办法（更详细内容见项目的wiki）

1. Macast被电脑防火墙拦截  
    手机尝试访问 http://电脑ip:1068，如:192.168.1.123:1068 如果出现helloworld 等字样排除问题。  
    *具体端口号见应用菜单设置的第一项，如果没有则为默认的1068*
2. 路由器问题  
    路由器开启UPnP，关闭ap隔离，确认固件正常（部分openwrt有可能有问题）
4. 手机软件有问题，体现为无法搜索到设备  
    可以重启软件或更换软件尝试，或向其他投屏接收端电视测试
    尝试在搜索页面等待久一点（最多1分钟如果搜不到那应该就是别的问题了）
    如操作系统为IOS，注意要开启软件的**本地网络发现**权限
5. 网络问题  
    请确定手机和电脑处在同一网段下，比如说：电脑连接光猫的网线，手机连接路由器wifi，这种情况大概率是不在同一网段的，可以查看手机和电脑的ip前缀是否相同。
6. 其他未知问题  
    尝试在同一局域网手机投电视，如果可以正常投说明问题还是出在电脑端，继续检查电脑问题或查看如何报告bug

## 如何报告bug
  准备以下信息，推荐到Github报告问题，点击 **[new issue](https://github.com/xfangfang/Macast/issues/new/choose)** 去反馈问题：
  1. 你的电脑系统类型和版本：如Win10 20h2
  2. 你使用的手机系统和软件：如 安卓 bilibili
  3. bug复现：如何复现bug与bug是否可以稳定复现
  4. 程序运行的log：  
    - windows下载debug版应用, cmd执行：https://github.com/xfangfang/Macast/releases/latest  
    - mac 终端输入：`/Applications/Macast.app/Contents/MacOS/Macast` 回车运行  
    - linux 安装deb后，命令行运行 `macast` \\ 直接从源码运行 \\ 包管理安装后命令行运行 `macast-cli`  

## 用户反馈

点击链接加入群聊【小方的软件工地】：[983730955](https://jq.qq.com/?_wv=1027&k=4ioK8gQs)

当然也可以考虑捐赠 ~~获得贵宾售后服务（开玩笑）~~ 支持Macast和他的开发者们为了这个软件熬过的日日夜夜

<img align="center" width="400" src="sponsorships.png" alt="sponsorships" height="auto"/>

<img align="center" width="400" src="https://service-65diwogz-1252652631.bj.apigw.tencentcs.com/release/sponsor.svg" alt="sponsors" height="auto"/>

## 使用截图
*如果系统设置为中文，Macast会自动切换中文界面*  

在投放视频或其他媒体文件后，可以点击应用图标复制媒体下载链接  
<img align="center" width="400" src="https://gitee.com/xfangfang/xfangfang/raw/master/assets/img/macast/copy_uri.png" alt="copy_uri" height="auto"/>

支持选择第三方播放器  
<img align="center" width="400" src="https://gitee.com/xfangfang/xfangfang/raw/master/assets/img/macast/select_renderer.png" alt="select_renderer" height="auto"/>


## 相关链接

[UPnP™ Device Architecture 1.1](http://upnp.org/specs/arch/UPnP-arch-DeviceArchitecture-v1.1.pdf)

[UPnP™ Resources](http://upnp.org/resources/upnpresources.zip)

[UPnP™ ContentDirectory:1 service](http://upnp.org/specs/av/UPnP-av-ContentDirectory-v1-Service.pdf)

[UPnP™ MediaRenderer:1 device](http://upnp.org/specs/av/UPnP-av-MediaRenderer-v1-Device.pdf)

[UPnP™ AVTransport:1 service](http://upnp.org/specs/av/UPnP-av-AVTransport-v1-Service.pdf)

[UPnP™ RenderingControl:1 service](http://upnp.org/specs/av/UPnP-av-RenderingControl-v1-Service.pdf)

[python-upnp-ssdp-example](https://github.com/ZeWaren/python-upnp-ssdp-example)
