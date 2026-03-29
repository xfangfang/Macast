# Macast Swift 版本用户手册

## 1. 项目概述

Macast 是一款基于 Swift 语言开发的 macOS 平台 DLNA 媒体渲染器应用程序，允许用户从移动设备将视频、图片或音乐推送到计算机进行播放。本手册将指导您如何使用 Macast Swift 版本。

## 2. 功能特性

- ✅ DLNA 媒体渲染协议支持
- ✅ 支持多种媒体格式（视频、音频、图片）
- ✅ 与主流 DLNA 客户端兼容（如：QQ 音乐、网易云音乐、腾讯视频、VLC 等）
- ✅ 支持 IINA 播放器集成
- ✅ 系统状态栏菜单控制
- ✅ 偏好设置自定义
- ✅ 自动设备发现

## 3. 安装方法

### 3.1 从源码构建

```bash
# 克隆仓库
git clone https://github.com/xfangfang/Macast.git
cd Macast/Macast

# 构建应用程序
swift build -c release --arch arm64 --arch x86_64

# 运行应用程序
./.build/apple/Products/Release/Macast.app/Contents/MacOS/Macast
```

### 3.2 使用打包脚本

```bash
# 使用提供的打包脚本
./package.sh --identity "Your Name (Team ID)" --version 1.1.0 --short 1.1
```

## 4. 使用方法

### 4.1 启动应用程序

双击 Macast.app 图标启动应用程序，您将在系统状态栏看到一个音乐图标。

### 4.2 启动/停止 DLNA 服务

1. 点击系统状态栏中的 Macast 图标
2. 选择「启动服务」开始 DLNA 服务
3. 选择「停止服务」停止 DLNA 服务

### 4.3 连接设备

1. 确保您的移动设备和计算机处于同一局域网
2. 在移动设备上打开 DLNA 兼容的应用程序（如：QQ 音乐、网易云音乐、腾讯视频等）
3. 查找并选择名为「Macast」的 DLNA 设备
4. 开始播放媒体，媒体将自动推送到您的计算机

### 4.4 偏好设置

1. 点击系统状态栏中的 Macast 图标
2. 选择「偏好设置」
3. 在偏好设置窗口中，您可以：
   - 选择默认的媒体渲染器（MPV、IINA、VLC）
   - 应用设置
   - 重置默认设置

### 4.5 关于 Macast

1. 点击系统状态栏中的 Macast 图标
2. 选择「关于 Macast」
3. 在关于窗口中，您可以查看应用程序版本和访问官方网站

## 5. 支持的播放器

Macast Swift 版本支持以下媒体播放器：

- **MPV**：轻量级媒体播放器
- **IINA**：基于 MPV 的 macOS 媒体播放器
- **VLC**：开源媒体播放器

## 6. 常见问题

### 6.1 无法找到 Macast 设备

**解决方案**：
- 确保您的移动设备和计算机处于同一局域网
- 检查 Macast 服务是否已启动
- 重启 Macast 应用程序
- 关闭计算机上的防火墙或允许 Macast 访问网络

### 6.2 媒体播放没有声音

**解决方案**：
- 检查计算机音量设置
- 检查移动设备音量设置
- 尝试切换到不同的媒体播放器

### 6.3 视频播放卡顿

**解决方案**：
- 确保您的网络连接稳定
- 尝试降低视频质量
- 关闭计算机上的其他占用资源的应用程序

### 6.4 应用程序崩溃

**解决方案**：
- 确保您使用的是最新版本的 Macast
- 尝试重置偏好设置
- 检查系统日志获取更多信息

## 7. 联系方式

- 官方网站：[https://github.com/xfangfang/Macast](https://github.com/xfangfang/Macast)
- Issue 反馈：[https://github.com/xfangfang/Macast/issues](https://github.com/xfangfang/Macast/issues)
- 邮箱：[xfangfang@126.com](mailto:xfangfang@126.com)

## 8. 更新日志

### Version 1.0.0

- ✅ 初始版本发布
- ✅ DLNA 协议支持
- ✅ 基本媒体播放功能
- ✅ 系统状态栏菜单
- ✅ 偏好设置窗口
- ✅ IINA 播放器集成
- ✅ 关于窗口

---

© 2026 Macast Team. All rights reserved.
