# Macast macOS平台Swift重写开发计划

## 1. 项目概述

Macast是一款基于Swift语言开发的macOS平台DLNA媒体渲染器应用程序，允许用户从移动设备将视频、图片或音乐推送到计算机进行播放。本开发计划结合了所有需求文档，按优先级制定了详细的任务列表和进度安排。

## 2. 开发阶段划分

### 阶段一：项目准备与核心框架搭建 (1-2周)
- 项目初始化
- 开发环境配置
- 版本控制设置
- 核心模块框架搭建

### 阶段二：核心功能开发 (3-4周)
- GUI模块开发
- 网络模块开发
- DLNA协议实现
- 播放器集成

### 阶段三：扩展功能开发 (2-3周)
- 插件系统开发
- IINA播放器集成
- 多协议支持框架

### 阶段四：测试与优化 (2-3周)
- 单元测试
- 集成测试
- 性能优化
- 用户体验优化
- 安全加固

### 阶段五：打包与发布 (1-2周)
- 打包脚本测试
- 应用签名与打包
- 文档编写
- 版本发布

## 3. 详细任务列表

以下是按优先级排序的详细任务列表：

### 高优先级任务 (必须完成的核心功能)

| 任务ID | 任务描述 | 优先级 | 时间估计 | 依赖关系 | 状态 |
|--------|----------|--------|----------|----------|------|
| 1 | 项目初始化：创建Swift Package项目结构 | 高 | 1天 | 无 | 待开始 |
| 2 | 配置开发环境：安装SwiftLint、SwiftFormat等工具 | 高 | 1天 | 无 | 待开始 |
| 3 | 设置版本控制：初始化Git仓库，配置.gitignore | 高 | 1天 | 无 | 待开始 |
| 4 | 开发GUI模块：菜单栏应用控制器(StatusMenuController) | 高 | 2天 | 1,2,3 | 已完成 |
| 5 | 开发网络模块：SSDPServer服务发现功能 | 高 | 3天 | 1,2,3 | 已完成 |
| 6 | 开发网络模块：HTTPServer实现 | 高 | 3天 | 1,2,3,5 | 已完成 |
| 7 | 开发DLNA协议模块：核心服务实现(ConnectionManager/AVTransport/RenderingControl) | 高 | 5天 | 1,2,3,6 | 已完成 |
| 8 | 开发播放器模块：MPVController实现 | 高 | 3天 | 1,2,3 | 已完成 |
| 9 | 实现DLNA媒体渲染功能：连接、播放、暂停、停止等核心操作 | 高 | 5天 | 4,7,8 | 已完成 |

### 中优先级任务 (重要的扩展功能)

| 任务ID | 任务描述 | 优先级 | 时间估计 | 依赖关系 | 状态 |
|--------|----------|--------|----------|----------|------|
| 10 | 开发插件系统核心：MacastPlugin协议和PluginManager | 中 | 3天 | 1,2,3 | 待开始 |
| 11 | 开发渲染器插件接口：DLNARenderer协议 | 中 | 2天 | 10 | 待开始 |
| 12 | 实现IINA播放器集成：IINARenderer插件 | 中 | 3天 | 11 | 待开始 |
| 13 | 开发偏好设置窗口：PreferencesWindowController | 中 | 3天 | 4 | 待开始 |
| 15 | 实现多协议支持框架：ProtocolManager | 中 | 3天 | 1,2,3 | 待开始 |
| 18 | 编写单元测试：核心模块测试用例 | 中 | 4天 | 5,6,7,8 | 待开始 |
| 19 | 编写集成测试：端到端功能测试 | 中 | 3天 | 9,18 | 待开始 |
| 20 | 性能优化：减少延迟，提高响应速度 | 中 | 3天 | 9 | 待开始 |
| 22 | 安全加固：网络安全，数据保护 | 中 | 2天 | 5,6 | 待开始 |
| 24 | 使用package.sh脚本进行打包测试 | 中 | 2天 | 9 | 待开始 |

### 低优先级任务 (可选的增强功能)

| 任务ID | 任务描述 | 优先级 | 时间估计 | 依赖关系 | 状态 |
|--------|----------|--------|----------|----------|------|
| 14 | 开发关于窗口：AboutWindowController | 低 | 1天 | 4 | 待开始 |
| 16 | 实现AirPlay协议支持（可选） | 低 | 5天 | 15 | 待开始 |
| 17 | 实现Chromecast协议支持（可选） | 低 | 5天 | 15 | 待开始 |
| 21 | 用户体验优化：界面美化，交互改进 | 低 | 2天 | 9 | 待开始 |
| 23 | 编写文档：用户手册，开发文档 | 低 | 3天 | 9 | 待开始 |
| 25 | 发布版本：准备发布包，上传到分发平台 | 低 | 2天 | 24,23 | 待开始 |

## 4. 开发流程和规范

### 4.1 代码提交流程

1. 创建特性分支：`git checkout -b feature/feature-name`
2. 编写代码并提交：`git commit -m "Add feature-name"`
3. 运行测试：`swift test`
4. 运行代码检查：`swiftlint && swiftformat .`
5. 推送分支：`git push origin feature/feature-name`
6. 创建Pull Request
7. 代码审查
8. 合并分支：`git merge feature/feature-name`

### 4.2 代码规范

- 遵循Swift官方代码风格指南
- 使用SwiftLint进行代码风格检查
- 使用SwiftFormat进行代码格式化
- 保持代码简洁、可读性强
- 为公共API添加文档注释

### 4.3 测试规范

- 为核心模块编写单元测试
- 编写集成测试确保模块间协作正常
- 测试覆盖率目标：核心功能≥80%
- 定期运行测试确保功能正常

## 5. 风险管理

### 5.1 技术风险

| 风险 | 影响 | 应对措施 |
|------|------|----------|
| DLNA协议实现复杂度 | 开发时间可能延长 | 分模块实现，先完成核心功能 |
| 播放器集成兼容性 | 可能存在兼容性问题 | 选择稳定的播放器版本，编写详细的集成测试 |
| 网络通信稳定性 | 可能影响服务发现和数据传输 | 增加错误处理和重试机制 |

### 5.2 项目管理风险

| 风险 | 影响 | 应对措施 |
|------|------|----------|
| 任务延期 | 项目进度可能延迟 | 合理安排任务优先级，预留缓冲时间 |
| 需求变更 | 可能导致重新开发 | 建立严格的需求变更流程，尽量减少变更 |
| 资源不足 | 可能影响项目进度 | 提前规划资源，确保所需工具和库可用 |

### 5.3 质量风险

| 风险 | 影响 | 应对措施 |
|------|------|----------|
| 代码质量问题 | 可能导致维护困难和bug | 严格执行代码审查和测试规范 |
| 用户体验不佳 | 可能影响用户满意度 | 定期进行用户体验测试和反馈收集 |
| 安全漏洞 | 可能导致安全问题 | 定期进行安全审查和测试 |

## 6. 进度跟踪

项目进度将通过以下方式进行跟踪：

1. 每周更新任务状态和进度
2. 使用Git提交记录和Pull Request跟踪代码变更
3. 定期召开项目进度会议（如果有团队）
4. 更新开发计划文档以反映最新进度和调整

## 7. 交付物

项目完成后将交付以下内容：

1. 完整的Macast应用程序
2. 源代码仓库
3. 详细的开发文档
4. 用户手册
5. 测试报告
6. 打包和发布脚本

---

本开发计划将根据实际开发情况进行调整和优化，确保项目按时、高质量完成。

## 8. 对照重构基线（Python 原版 → Swift）

### 8.1 目标与原则

- 以 `/Users/zliz/Downloads/Macast/Macast-py` 作为行为基准，实现 Swift 重构版本与原版在 DLNA/UPnP 客户端侧表现一致
- 优先保证协议兼容性与可验证性：先跑通“发现→描述→控制→播放→状态回读”的最小闭环，再做架构优化与插件扩展
- HTTP 路由与对外接口优先对齐原版，避免客户端兼容性差异导致排错困难

### 8.2 必须对齐的差异点（按影响优先级）

1. HTTP 路由结构
   - 原版（Python）：`/description.xml`、`/dlna/*.xml`（SCPD 等静态 XML）、`/<service>/action`（SOAP）、`/<service>/event`（SUBSCRIBE/UNSUBSCRIBE）
   - Swift：对齐为原版路由表，并按 service 分发到对应处理器
2. SOAP Action 解析与分发
   - Swift 需要从请求头/请求体解析出 action，并确保能命中 AVTransport/RenderingControl/ConnectionManager 的动作分支
3. SSDP 发现/广播一致性
   - 对齐原版的多 USN 注册（rootdevice、MediaRenderer、三大 Service）与 alive 周期广播
   - LOCATION 指向局域网可访问地址（非 localhost），并具备合理的多网卡选择策略
4. mpv 控制与状态同步
   - Swift 侧采用 mpv JSON IPC + observe_property 进行状态观测（position/duration/volume/mute/pause/speed 等），并将状态回写到 DLNA service
5. 插件体系边界（后置）
   - 第一里程碑默认 renderer=mpv、protocol=DLNA，先跑通闭环；插件加载/商店等作为后续阶段实现

### 8.3 第一里程碑（DLNA + mpv 跑通）验收标准

1. 发现层（SSDP）
   - 手机 DLNA 客户端能发现设备
   - 对 `ssdp:all` / `upnp:rootdevice` / `MediaRenderer` / 三大 Service 的 ST 查询可得到合理响应
   - `LOCATION` 为 `http://<LAN-IP>:<port>/description.xml`
2. 描述层（HTTP GET）
   - `GET /description.xml` 返回可被客户端解析的 MediaRenderer 描述
   - `GET /dlna/AVTransport.xml`、`/dlna/RenderingControl.xml`、`/dlna/ConnectionManager.xml` 可访问
3. 控制层（SOAP POST）
   - `POST /AVTransport/action`：SetAVTransportURI、Play、Pause、Stop、Seek 均可调用且返回正确 SOAP 响应
   - `POST /RenderingControl/action`：SetVolume、SetMute 生效
4. 播放层（mpv）
   - SetAVTransportURI + Play 后 mpv 实际播放媒体
   - Pause/Seek/Stop 对播放器生效
   - GetTransportInfo/GetPositionInfo/GetVolume 的回读状态与播放器一致（事件订阅可作为后续里程碑补齐）

## 9. 里程碑1执行计划（路由对齐 + DLNA+mpv 跑通）

### 9.1 执行目标

- Swift 版本对齐 Python 原版对外接口与核心行为，完成 8.3 的验收标准

### 9.2 任务分解

#### Task 1：建立可验证基线

- [x] 运行 `swift test`，确保当前基线通过
- [x] 运行 `npx gitnexus analyze`，确保后续能做影响分析（如需保留 embeddings，改用 `npx gitnexus analyze --embeddings`）

#### Task 2：HTTPServer 路由对齐（原版路由表）

- [x] 修改 Swift HTTPServer 路由为：
  - `GET /description.xml`
  - `GET /dlna/<name>.xml`（至少包含 AVTransport/RenderingControl/ConnectionManager）
  - `POST /<service>/action`
  - `SUBSCRIBE /<service>/event`、`UNSUBSCRIBE /<service>/event`（可先作为里程碑1.5实现）
- [x] 设备描述中的 URLBase/UDN/服务 URL 路径与上述路由一致，并确保 URLBase 使用 LAN 可访问 IP
- [x] 通过本地请求验证：
  - `curl http://<LAN-IP>:<port>/description.xml` 返回 200 且内容为 XML
  - `curl http://<LAN-IP>:<port>/dlna/AVTransport.xml` 等返回 200

#### Task 3：SOAP Action 解析与分发对齐

- [x] 修正 SOAP Action 解析逻辑：优先读取 `SOAPACTION` 头（去除引号），缺失时从 body 解析 action 元素
- [x] 修正参数解析逻辑：仅解析 action 元素内的参数键值对，避免误解析 Envelope/Body 等标签
- [x] 验证 `POST /AVTransport/action` 的 SetAVTransportURI/Play/Pause/Stop/Seek 可被调用并返回 200 + 正确 SOAP 响应
- [x] 验证 `POST /RenderingControl/action` 的 SetVolume/SetMute 生效

#### Task 4：SSDP 对齐（发现/广播/LOCATION）

- [x] SSDP 响应 LOCATION 指向 `http://<LAN-IP>:<port>/description.xml`
- [x] 支持原版 USN/ST 组合（rootdevice、MediaRenderer、三大 Service），并对 `ssdp:all` 返回全量响应
- [x] 基本 alive 周期广播对齐（可先满足能发现与稳定在线）

#### Task 5：mpv IPC 对齐（状态观测驱动）

- [x] Swift MPVController 使用 mpv JSON IPC socket，并实现 observe_property（volume/time-pos/pause/mute/duration/speed/sub 等）
- [x] 播放器状态通过 DLNAMediaRenderer 回写到 AVTransport/RenderingControl service（至少覆盖 position/duration/transportState/volume/mute）

#### Task 6：集成与验收

- [x] 启动流程：菜单栏启动服务时同时启动 HTTPServer + SSDP + 渲染器（默认 mpv）
- [x] 按 8.3 验收标准完成端到端验证（发现→描述→控制→播放→状态回读）

### 9.3 验证命令（建议）

- `swift test`
- `swiftlint`（如项目配置可用）
