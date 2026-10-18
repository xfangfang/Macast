# Macast v0.8 — Native Apple Silicon

第一个原生 Apple Silicon 版本。arm64 only，不使用 Rosetta，也不是 universal2 双架构。

Verified on **macOS 15 / Apple M4 Pro**. Upstream `xfangfang/Macast` is still tracked as
`origin` and fetched normally.

---

## 为什么发这个版本

投屏一直有个问题：手机能发现设备、能发送媒体，但 Macast 一点反应都没有——没有窗口，没有报错，
手机侧还显示「正在播放」。这个版本修掉了它，以及一路上挖出的另外几个问题。

### 真正的原因：loadfile 少了 index 参数

mpv 的命令签名是：

```
loadfile <url> [flags] [index] [options]
```

代码发送的是 `loadfile <url> replace start=0.0`——options 串落在了第三位。
mpv 于是把 `start=0.0` 当成 index 解析，**整条命令被拒绝**：

```
[ipc_0] The loadfile option must be an integer: start=0.0
[ipc_0] Command loadfile: argument index can't be parsed
```

致命的地方在于：对一条它随后拒绝执行的命令，`loadfile` 依然回 `success`，
而 DLNA 层无论结果如何都报 `PLAYING`。所以从手机看，「设备在线但不播」和「一切正常」完全无法区分。

现在 index 被显式传入。

### 窗口在 macOS 15 上不可见（三个独立原因）

| 问题 | 原因 | 处理 |
|---|---|---|
| 窗口沉在桌面下 | `--ontop-level=system` 把窗口放到 `kCGDesktopWindowLevel`（CG layer 26），在桌面图标和壁纸之下 | 移除，单独用 `--ontop` |
| 窗口在屏幕外 | `--geometry` 按整个虚拟桌面解析，在存在失效显示器条目的机器上算出 `(1763, -1596)` | 完全移除，不传时 mpv 自己居中是准的 |
| 尺寸位置被改写 | 即使传入按主屏算好的绝对像素，mpv 也会用视频原始尺寸覆盖尺寸再重算位置 | 同上 |

> **代价（需要知道）**：去掉 `--geometry` 是窗口落对的必要条件，因此 macOS 上的
> **「播放器位置」设置不再生效**（窗口一律居中）。这是有意取舍。

### 静默失败现在会被报出来

- **mpv 的输出会落盘**到 `~/Library/Application Support/Macast/macast_python.log`。
  此前这些信息全部丢失：`--no-terminal` 抑制了一切，而 `proc.communicate()` 要等 mpv 退出后才读管道。
  另外 mpv 的输出走 **stdout**，不是 stderr。
- **播放会被校验**：`loadfile` 之后检查 `idle-active`，若流打不开则写日志并弹出菜单栏通知
  「无法播放此媒体」，而不是毫无反应。
- **renderer 判空**：`SetAVTransportURI` 只取一次 renderer 并检查，之前取三次然后让 `None`
  的 `AttributeError` 被 CherryPy 吞掉、客户端照样收到 `200`。

> **一个常见误解**：DLNA 客户端下发的是**带时效签名**的链接（如咪咕的
> `timestamp`/`SecurityKey`）。过期后 CDN 返回 **403**，此时 Macast 播不了是正常的——
> 手机上那个视频刚点开就投即可。现在这种情况会明确弹通知，不再静默。

### arm64 适配

- `netifaces`（已停止维护、无 arm64 wheel）→ `psutil`
- 删除失效的 `lxml` 依赖
- 内置 arm64 版 mpv 0.41.0，MoltenVK 的 ICD manifest 发布到 Vulkan loader
  **真正查找**的路径 `Contents/Resources/vulkan/icd.d`。缺了它 mpv 会退回软件渲染，
  每一帧都报 `Failed initializing any suitable GPU context`
- 通过 `sys.executable` 定位内置 mpv（PyInstaller 打包后工作目录是错的）
- CI 现代化

---

## 构建

```shell
python3 -m venv /tmp/macast_v
/tmp/macast_v/bin/pip install PyInstaller psutil lxml \
    pyobjc-core pyobjc-framework-Cocoa pyobjc-framework-Quartz
PYTHON=/tmp/macast_v/bin/python3 ./build-macos-arm64.sh
```

### 构建期三道校验

| # | 检查 | 作用 |
|---|---|---|
| 1 | mpv 能创建 GPU context | 拦住软件渲染悄悄降级 |
| 2 | 窗口在可见 CG 层且完整落在主屏内 | 拦住桌面层 / 屏幕外 |
| 3 | **mpv 能通过 IPC 真正播放远程流** | **唯一能抓住本次投屏 bug 的一道** |

第 3 道使用与 `set_media_url()` **完全一致**的参数列表，缺网时跳过而不报错。

本次构建输出：

```
architecture: arm64
all .so are arm64
mpv GPU context OK
mpv window on CG layer 3, inside the primary screen
mpv loads and plays over IPC
```

---

## 改动规模

相对上游 `v0.7`：16 个文件，+1213 / -111，其中 10 个代码/构建文件。

## 安装

- **Apple Silicon**：本仓库暂无预编译安装包，请用上面的脚本自行构建
- **Windows / Linux / Intel Mac**：仍从 [上游 release](https://github.com/xfangfang/Macast/releases/latest) 获取

## 反馈

遇到问题请附上 `~/Library/Application Support/Macast/macast_python.log`——
现在 mpv 的原始报错都在里面，能直接看出是链接失效、解码不支持还是别的什么原因。
