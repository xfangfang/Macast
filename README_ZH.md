# Macast

<img align="right" src="https://raw.githubusercontent.com/xfangfang/Macast/main/demo.png?raw=true" alt="demo" width="256" height="auto"/> Macast是一个跨平台的 **菜单栏\状态栏** 应用，用户可以通过他来接收视频、图片和音乐，支持主流视频音乐软件和其他任何符合DLNA协议的投屏.

目前支持的平台 🖥 :

- [x] MacOS 10.15至最新系统
- [x] Gnome (在ubuntu20.04测试通过)
- [x] KDE (在kubuntu21.04测试通过)
- [x] Other Linux under xorg (在Raspberry Pi OS测试通过)
- [x] Windows (beta)

对于linux用户，如果您的设备不能正常运行，请参考这个链接解决: https://pystray.readthedocs.io/en/latest/usage.html#selecting-a-backend

## 安装

进入页面选择对应的操作系统下载即可。

- ### MacOS

下载地址:  [Macast_v*_darwin.zip](https://github.com/xfangfang/Macast/releases/latest)

- ### Windows

下载地址:  [Macast_v*_windows_debug.zip](https://github.com/xfangfang/Macast/releases/latest)

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

提示:
1. 确保你安装了 **mpv**:

```
# 例：在ubuntu上安装mpv
sudo apt install mpv
```

2. 确保可以在python中使用 **gi**:

```
$ python3
Python 3.7.10 (default, Jun  3 2021, 17:51:26)
Type "help", "copyright", "credits" or "license" for more information.
>>> import gi
>>>
```

如果出现了问题, 请尝试安装python3-gi: **sudo apt-get install python3-gi**

对于使用conda的用户 **gi** 可能存在问题, 请参考这个链接解决问题: https://stackoverflow.com/a/40303128


## 使用方法

打开应用后，**菜单栏\状态栏** 会出现一个图标，这时你的设备就可以接收来自同一局域网的DLNA投放了。

`注意：本应用在MacOS上会创建 ~/Library/Application\ Support/Macast 目录用于保存应用的配置信息`


## MacOS下开发环境部署

### 下载mpv

```shell
wget https://laboratory.stolendata.net/~djinn/mpv_osx/mpv-latest.tar.gz
mkdir -p bin && tar --strip-components 2 -C bin -xzvf mpv-latest.tar.gz mpv.app/Contents/MacOS
```

### 调试

```shell
pip install -r requirements.txt
python Macast.py
```

`注意：第一次运行时mpv启动较慢需要等待片刻`

### 打包

```shell
pip install py2app
pip install setuptools==44.0.0 # 可选，高版本打包出来的应用在我的电脑上有问题
python setup.py py2app
cp -R bin dist/Macast.app/Contents/Resources/
open dist
```

`注意：打包好之后在dist目录下就能找到编译好的内容了`


## 相关链接

[UPnP™ Device Architecture 1.1](http://upnp.org/specs/arch/UPnP-arch-DeviceArchitecture-v1.1.pdf)

[python-upnp-ssdp-example](https://github.com/ZeWaren/python-upnp-ssdp-example)

[pystray](https://github.com/moses-palmer/pystray)
