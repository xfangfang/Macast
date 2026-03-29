# Macast Swift 版本未来开发计划

## 1. 项目概述

基于 Macast macOS 平台 Swift 重写的成功完成，本计划制定了未来版本的增强功能开发路线图。主要目标是扩展媒体协议支持、增加播放器集成选项、提升用户体验和完善插件系统。

## 2. 开发阶段划分

### 阶段一：协议扩展与播放器集成 (3-4周)
- 增加 AirPlay 协议支持
- 实现 Chromecast 协议支持
- 集成更多媒体播放器 (VLC, QuickTime)

### 阶段二：用户界面增强 (2-3周)
- 暗色模式支持
- 通知中心集成
- 媒体播放控制条

### 阶段三：插件系统扩展 (2-3周)
- YouTube 插件
- 浏览器扩展支持
- 插件市场功能

## 3. 详细任务列表

### 高优先级任务 (核心功能扩展)

| 任务ID | 任务描述 | 优先级 | 时间估计 | 依赖关系 | 状态 |
|--------|----------|--------|----------|----------|------|
| F3 | 增加AirPlay协议支持：AirPlayProtocol实现 | 高 | 5天 | 无 | 待开始 |
| F4 | 增加AirPlay协议支持：AirPlay渲染器接口 | 高 | 3天 | F3 | 待开始 |
| F5 | 实现Chromecast协议支持：ChromecastProtocol实现 | 高 | 5天 | 无 | 待开始 |
| F6 | 实现Chromecast协议支持：Chromecast渲染器接口 | 高 | 3天 | F5 | 待开始 |
| F12 | 添加更多插件扩展功能：插件市场功能 | 高 | 7天 | 无 | 待开始 |

### 中优先级任务 (重要功能增强)

| 任务ID | 任务描述 | 优先级 | 时间估计 | 依赖关系 | 状态 |
|--------|----------|--------|----------|----------|------|
| F1 | 支持更多媒体播放器：VLC播放器集成 | 中 | 4天 | 无 | 待开始 |
| F2 | 支持更多媒体播放器：QuickTime Player集成 | 中 | 3天 | 无 | 待开始 |
| F10 | 添加更多插件扩展功能：YouTube插件 | 中 | 4天 | 无 | 待开始 |
| F11 | 添加更多插件扩展功能：浏览器扩展支持 | 中 | 5天 | 无 | 待开始 |

### 低优先级任务 (用户体验优化)

| 任务ID | 任务描述 | 优先级 | 时间估计 | 依赖关系 | 状态 |
|--------|----------|--------|----------|----------|------|
| F7 | 增强用户界面：暗色模式支持 | 低 | 3天 | 无 | 待开始 |
| F8 | 增强用户界面：通知中心集成 | 低 | 2天 | 无 | 待开始 |
| F9 | 增强用户界面：媒体播放控制条 | 低 | 4天 | 无 | 待开始 |

## 4. 技术实现细节

### 4.1 AirPlay 协议支持

**核心功能**：
- AirPlayProtocol 类实现 AirPlay 协议
- AirPlayRendererProtocol 接口定义 AirPlay 渲染器行为
- 支持 AirPlay 视频和音频流
- 与现有 ProtocolManager 集成

**关键文件**：
- `Sources/Macast/ProtocolSupport/AirPlayProtocol.swift`
- `Sources/Macast/PluginSystem/Renderers/AirPlayRendererProtocol.swift`

### 4.2 Chromecast 协议支持

**核心功能**：
- ChromecastProtocol 类实现 Chromecast 协议
- ChromecastRendererProtocol 接口定义 Chromecast 渲染器行为
- 支持 Cast 设备发现和媒体控制
- 与现有 ProtocolManager 集成

**关键文件**：
- `Sources/Macast/ProtocolSupport/ChromecastProtocol.swift`
- `Sources/Macast/PluginSystem/Renderers/ChromecastRendererProtocol.swift`

### 4.3 播放器集成扩展

**VLC 播放器集成**：
- 使用 AppleScript 与 VLC 通信
- 实现 VLCRenderer 类
- 支持媒体播放控制

**QuickTime Player 集成**：
- 使用 AppleScript 与 QuickTime 通信
- 实现 QuickTimeRenderer 类
- 支持基本播放控制

### 4.4 用户界面增强

**暗色模式支持**：
- 为所有 UI 组件添加暗色模式适配
- 使用系统外观自动切换

**通知中心集成**：
- 播放状态变化通知
- 设备连接通知

**媒体播放控制条**：
- 浮动控制条显示当前播放状态
- 支持播放、暂停、进度控制

### 4.5 插件系统扩展

**YouTube 插件**：
- 支持 YouTube 视频播放
- 解析 YouTube 视频链接

**浏览器扩展支持**：
- 开发 Chrome/Safari 浏览器扩展
- 支持从浏览器推送媒体到 Macast

**插件市场功能**：
- 插件在线发现和安装
- 插件版本管理和更新

## 5. 开发流程和规范

沿用原有项目的开发流程和规范：

- 遵循 Swift 官方代码风格指南
- 使用 SwiftLint 进行代码风格检查
- 使用 SwiftFormat 进行代码格式化
- 为核心模块编写单元测试
- 编写集成测试确保模块间协作正常
- 测试覆盖率目标：核心功能≥80%

## 6. 风险管理

### 6.1 技术风险

| 风险 | 影响 | 应对措施 |
|------|------|----------|
| AirPlay/Chromecast协议复杂度 | 开发时间可能延长 | 分模块实现，优先完成核心功能 |
| 播放器集成兼容性 | 可能存在兼容性问题 | 选择稳定的播放器版本，编写详细的集成测试 |
| 插件市场安全性 | 可能引入恶意插件 | 实现插件签名和验证机制 |

## 7. 进度跟踪

- 每周更新任务状态和进度
- 使用 Git 提交记录和 Pull Request 跟踪代码变更
- 定期更新开发计划文档以反映最新进度

## 8. 交付物

- 完整的 Macast 增强版本
- 更新的源代码仓库
- 详细的开发文档
- 更新的用户手册
- 测试报告

---

本开发计划将根据实际开发情况进行调整和优化，确保项目按时、高质量完成。