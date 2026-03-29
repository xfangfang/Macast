# Macast Swift 版本开发指南

## 1. 项目概述

Macast 是一款基于 Swift 语言开发的 macOS 平台 DLNA 媒体渲染器应用程序。本指南将介绍 Macast Swift 版本的架构设计、开发流程和代码结构，帮助开发者快速上手开发工作。

## 2. 架构设计

### 2.1 核心模块

Macast Swift 版本采用模块化架构设计，主要包含以下核心模块：

| 模块名称 | 主要职责 | 文件位置 |
|---------|--------|---------|
| **ProtocolManager** | 协议注册、管理和请求处理 | Sources/Macast/ProtocolSupport/ProtocolManager.swift |
| **DLNAProtocol** | DLNA 协议实现 | Sources/Macast/ProtocolSupport/DLNAProtocol.swift |
| **PluginSystem** | 插件加载、管理和依赖处理 | Sources/Macast/PluginSystem/ |
| **DLNARenderer** | DLNA 渲染器接口 | Sources/Macast/PluginSystem/Renderers/DLNARendererProtocol.swift |
| **StatusMenu** | 状态栏菜单控制 | Sources/Macast/StatusMenuController.swift |
| **Preferences** | 偏好设置管理 | Sources/Macast/Preferences/ |
| **AboutWindow** | 关于窗口 | Sources/Macast/AboutWindowController.swift |

### 2.2 关键类图

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│ StatusMenuController │◄─┼─► ProtocolManager   │◄─┼─► DLNAProtocol  │
└─────────────────┘      └─────────────────┘      └─────────────────┘
        ▲                        ▲                        ▲
        │                        │                        │
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│ PreferencesWindowController │  │ PluginManager     │  │ HTTPServer     │
└─────────────────┘      └─────────────────┘      └─────────────────┘
        ▲                        ▲                        ▲
        │                        │                        │
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│ AboutWindowController │  │ MacastPlugin    │  │ SSDPServer     │
└─────────────────┘      └─────────────────┘      └─────────────────┘
```

### 2.3 插件系统

Macast Swift 版本采用插件化设计，通过 `MacastPlugin` 协议实现插件扩展：

```swift
public protocol MacastPlugin {
    var identifier: String { get }
    var name: String { get }
    var version: String { get }
    var description: String { get }
    var dependencies: [PluginDependency] { get }
    
    func initialize() throws
    func cleanup() throws
}
```

## 3. 开发环境配置

### 3.1 系统要求

- macOS 11.0+
- Xcode 13.0+
- Swift 5.5+

### 3.2 项目结构

```
Macast/
├── Sources/
│   └── Macast/
│       ├── ProtocolSupport/
│       ├── PluginSystem/
│       ├── Preferences/
│       ├── StatusMenuController.swift
│       ├── AboutWindowController.swift
│       └── main.swift
├── Tests/
│   └── MacastTests/
├── Package.swift
├── package.sh
└── Development_Plan.md
```

### 3.3 构建命令

```bash
# 构建项目
swift build

# 运行项目
swift run

# 运行测试
swift test

# 构建发布版本
swift build -c release
```

## 4. 代码开发

### 4.1 开发流程

1. **创建特性分支**：`git checkout -b feature/feature-name`
2. **编写代码**：实现新功能或修复 bug
3. **运行测试**：确保代码通过所有测试
4. **代码审查**：提交代码进行审查
5. **合并分支**：将特性分支合并到主分支

### 4.2 代码规范

- 遵循 Swift 官方代码风格指南
- 使用清晰、描述性的命名
- 为公共 API 添加文档注释
- 实现适当的错误处理
- 确保代码可测试性

### 4.3 插件开发

要开发一个新的 Macast 插件，需要：

1. 实现 `MacastPlugin` 协议
2. 注册插件到 `PluginManager`
3. 处理插件生命周期
4. 实现媒体渲染功能

**示例插件结构**：

```swift
class MyRendererPlugin: MacastPlugin {
    var identifier: String { "com.example.myrenderer" }
    var name: String { "My Renderer" }
    var version: String { "1.0.0" }
    var description: String { "自定义媒体渲染器" }
    
    func initialize() throws {
        // 插件初始化逻辑
    }
    
    func cleanup() throws {
        // 插件清理逻辑
    }
}
```

## 5. 测试

### 5.1 单元测试

Macast Swift 版本包含完整的单元测试套件：

```bash
# 运行单元测试
swift test
```

主要测试文件：
- PluginDependencyTests.swift
- DLNARendererProtocolTests.swift
- ProtocolManagerTests.swift

### 5.2 集成测试

```bash
# 运行集成测试
swift test -c release --filter IntegrationTests
```

集成测试验证模块之间的协作是否正常，确保端到端功能正常工作。

## 6. 打包与发布

### 6.1 使用打包脚本

Macast Swift 版本提供了 `package.sh` 脚本用于打包应用程序：

```bash
# 使用打包脚本
./package.sh --identity "Your Name (Team ID)" --version 1.1.0 --short 1.1
```

### 6.2 签名与发布

1. 确保已安装 Apple Developer Certificate
2. 使用 `package.sh` 脚本进行签名和打包
3. 上传到分发平台或直接发布

## 7. 调试技巧

### 7.1 启用调试日志

在代码中添加调试日志：

```swift
print("调试信息: variable)")
```

### 7.2 使用 Xcode 调试

```bash
# 生成 Xcode 项目
swift package generate-xcodeproj

# 打开 Xcode 项目
open Macast.xcodeproj
```

在 Xcode 中设置断点和调试器进行调试。

## 8. 贡献指南

### 8.1 提交代码

1. Fork 项目仓库
2. 创建特性分支
3. 提交代码更改
4. 推送分支到远程仓库
5. 创建 Pull Request

### 8.2 报告问题

如果您发现了 bug 或有新功能建议，请通过以下方式报告：

- GitHub Issues：https://github.com/xfangfang/Macast/issues
- 提供详细的问题描述和重现步骤

## 9. 技术文档

- Swift 官方文档：https://docs.swift.org/
- AppKit 文档：https://developer.apple.com/documentation/appkit/
- DLNA 标准：https://www.dlna.org/
- UPnP 规范：https://openconnectivity.org/

## 10. 许可证

Macast Swift 版本采用 MIT 许可证发布：

```
MIT License

Copyright (c) 2026 xfangfang

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

© 2026 Macast Team. All rights reserved.
