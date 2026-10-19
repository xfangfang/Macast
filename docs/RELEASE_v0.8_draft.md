# v0.8 — Native Apple Silicon

arm64 only. No Rosetta, no universal2 binary. Verified on macOS 15 / Apple M4 Pro.

## 修复：投屏能发现设备但始终不播放

真正的原因不是窗口，而是 mpv 命令被拒了。签名是 `loadfile <url> [flags] [index] [options]`，
代码漏了 index，options 串被当成 index 解析：

```
[ipc_0] The loadfile option must be an integer: start=0.0
[ipc_0] Command loadfile: argument index can't be parsed
```

`loadfile` 对这条它随后拒绝执行的命令仍回 `success`，DLNA 层又无论结果都报 `PLAYING`——
所以从手机看，「连上了但不播」和「一切正常」无法区分。

## 修复：窗口在 macOS 15 上不可见

三个独立原因：`--ontop-level=system` 把窗口放到桌面层（layer 26）；
`--geometry` 按整个虚拟桌面解析会算出屏幕外坐标；即使给绝对像素，mpv 也会用视频原始尺寸覆盖再重算位置。
三者都指向同一个处理：去掉 `--geometry`，让 mpv 自己居中。

> **代价**：macOS 的「播放器位置」设置不再生效（窗口一律居中）。这是有意取舍。

## 改进：失败不再静默

- mpv 输出落盘到 `~/Library/Application Support/Macast/macast_python.log`
  （此前 `--no-terminal` 加上管道只在进程退出后才读，信息全丢；mpv 走 stdout 不是 stderr）
- `loadfile` 后校验 `idle-active`，流打不开就写日志 + 弹菜单栏通知
- `SetAVTransportURI` 取一次 renderer 并判空

> 客户端下发的是**带时效签名**的链接，过期后 CDN 返回 403，播不了是正常的。
> 刚点开就投即可；现在这种情况会明确弹通知。

## arm64 适配

`netifaces` → `psutil`（前者无 arm64 wheel）、删除失效的 `lxml` 依赖、
内置 arm64 mpv 0.41.0 并把 MoltenVK ICD manifest 发布到 Vulkan loader 真正查找的路径、
用 `sys.executable` 定位内置 mpv、CI 现代化。

## 构建

```shell
python3 -m venv /tmp/macast_v
/tmp/macast_v/bin/pip install PyInstaller psutil lxml \
    pyobjc-core pyobjc-framework-Cocoa pyobjc-framework-Quartz
PYTHON=/tmp/macast_v/bin/python3 ./build-macos-arm64.sh
```

构建期三道校验：GPU context → 窗口可见且在主屏内 → **能否通过 IPC 真正播放远程流**。
第三道是唯一能抓住本次投屏 bug 的。

## 说明

- 本仓库暂无预编译安装包，请自行构建
- Windows / Linux / Intel Mac 请用[上游 release](https://github.com/xfangfang/Macast/releases/latest)
- 反馈问题请附上 `macast_python.log`
