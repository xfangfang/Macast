# Macast macOS平台Swift重写项目配置

## 1. 开发环境配置

### 1.1 Swift Toolchain

**版本要求**：Swift 5.5 及以上

**安装方式**：
1. 安装Command Line Tools：
   ```bash
   xcode-select --install
   ```
2. 安装Swift工具链（可选，用于最新版本）：
   ```bash
   brew install swift-language
   ```

**配置**：
- 确保Swift版本为5.5+：
  ```bash
  swift --version
  ```
- 配置代码签名（用于打包应用）
- 配置应用沙箱权限

### 1.2 SwiftLint

**用途**：Swift代码风格检查工具

**安装方式**：
```bash
brew install swiftlint
```

**配置**：
在项目根目录创建`.swiftlint.yml`文件：
```yaml
# 基本配置
defaults:
  indentation: 4
  line_length: 120
  file_length:
    warning: 400
    error: 800

# 规则配置
rules:
  - identifier_name
  - type_name
  - variable_name
  - function_parameter_count
  - force_cast
  - force_try
  - empty_count
  - trailing_whitespace
  - vertical_whitespace
  - cyclomatic_complexity
  - nesting

# 排除配置
excluded:
  - Carthage
  - Pods
  - .build
```

### 1.3 SwiftFormat

**用途**：Swift代码格式化工具

**安装方式**：
```bash
brew install swiftformat
```

**配置**：
在项目根目录创建`.swiftformat`文件：
```
# 基本配置
indent: 4
linebreaks: lf
indentOperator: atStartOfLine
trailingCommas: none
trailingNewlines: 1

# 规则配置
--no-spaceAroundGenericBrackets
--no-spaceInsideBrackets
--no-wrapMultilineStatementBraces
--no-indentSwitchCase
```

### 1.4 Git

**版本要求**：Git 2.0 及以上

**安装方式**：
```bash
brew install git
```

**配置**：
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config --global core.editor "nano"
git config --global color.ui true
```

## 2. 依赖管理

### 2.1 Swift Package Manager (SPM)

**用途**：Swift官方的依赖管理工具

**配置**：
在`Package.swift`文件中添加依赖：
```swift
// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "Macast",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(name: "Macast", targets: ["Macast"])
    ],
    dependencies: [
        // 添加依赖
    ],
    targets: [
        .executableTarget(
            name: "Macast",
            dependencies: []),
        .testTarget(
            name: "MacastTests",
            dependencies: ["Macast"])
    ]
)
```

### 2.2 CocoaPods (可选)

**用途**：iOS/macOS平台常用的依赖管理工具

**安装方式**：
```bash
gem install cocoapods
```

**配置**：
在项目根目录创建`Podfile`文件：
```ruby
platform :osx, '10.15'

use_frameworks!

target 'Macast' do
  # 添加依赖
end
```

## 3. 测试工具

### 3.1 XCTest

**用途**：Swift官方的测试框架

**配置**：
Xcode默认集成了XCTest，无需额外配置。

### 3.2 Mockingbird

**用途**：Swift的Mock框架

**安装方式**：
```bash
brew install mockingbirdframework/mockingbird/mockingbird
```

**配置**：
在`Package.swift`中添加依赖：
```swift
dependencies: [
    .package(url: "https://github.com/birdrides/mockingbird.git", from: "0.20.0")
],
targets: [
    .testTarget(
        name: "MacastTests",
        dependencies: [
            "Macast",
            .product(name: "Mockingbird", package: "mockingbird")
        ]
    )
]
```

### 3.3 KIF (可选)

**用途**：UI测试框架

**安装方式**：
使用CocoaPods安装：
```ruby
pod 'KIF', '~> 3.17.0'
```

## 4. 框架和库

### 4.1 macOS系统框架

| 框架 | 用途 |
|------|------|
| AppKit | GUI框架 |
| Network.framework | 网络框架 |
| ServiceManagement.framework | 启动项管理 |
| UserNotifications.framework | 通知系统 |
| SystemConfiguration.framework | 网络配置 |
| Foundation | 基础框架 |

### 4.2 第三方库

#### 4.2.1 MPV

**用途**：媒体播放器

**安装方式**：
```bash
brew install mpv
```

**集成方式**：
通过Process调用MPV命令行工具，或使用MPV的Swift绑定库。

#### 4.2.2 IINA (可选)

**用途**：媒体播放器

**安装方式**：
从官网下载并安装：https://iina.io/

**集成方式**：
通过AppleScript或URL Scheme控制IINA。

#### 4.2.3 SwiftyXMLParser

**用途**：XML解析库

**安装方式**：
使用SPM安装：
```swift
.package(url: "https://github.com/yahoojapan/SwiftyXMLParser.git", from: "5.0.0")
```

#### 4.2.4 Logging

**用途**：日志库

**安装方式**：
使用SPM安装：
```swift
.package(url: "https://github.com/apple/swift-log.git", from: "1.4.0")
```

## 5. 技能要求

### 5.1 编程语言

- Swift 5.5+：项目开发语言
- Objective-C：与系统框架交互（可选）

### 5.2 平台开发

- macOS应用开发：AppKit框架使用
- 菜单栏应用开发：NSStatusItem使用
- 偏好设置窗口开发：NSPreferencePane使用

### 5.3 网络编程

- TCP/UDP网络编程：Network.framework使用
- HTTP服务器开发：处理DLNA请求
- SSDP协议实现：服务发现

### 5.4 协议实现

- DLNA/UPnP协议：ConnectionManager、AVTransport、RenderingControl服务
- SOAP协议：处理DLNA请求
- XML解析：处理DLNA设备描述和控制消息

### 5.5 播放器集成

- MPV集成：Process调用和IPC通信
- IINA集成：AppleScript控制
- 播放状态监控：进度、音量、静音等

### 5.6 插件系统设计

- 动态库加载：NSBundle使用
- 协议定义：Swift协议使用
- 插件注册和管理：插件注册表实现

## 6. 项目结构

```
Macast/
├── Sources/
│   ├── Macast/
│   │   ├── AppDelegate.swift
│   │   ├── StatusMenuController.swift
│   │   ├── PreferencesWindowController.swift
│   │   ├── AboutWindowController.swift
│   │   ├── SSDPServer.swift
│   │   ├── HTTPServer.swift
│   │   ├── DLNAProtocol.swift
│   │   ├── MPVController.swift
│   │   ├── IINARenderer.swift
│   │   ├── PluginManager.swift
│   │   ├── Settings.swift
│   │   ├── Logging.swift
│   │   └── NetworkUtils.swift
│   └── MacastLauncher/
│       └── main.swift
├── Tests/
│   ├── MacastTests/
│   │   ├── SSDPServerTests.swift
│   │   ├── HTTPServerTests.swift
│   │   ├── DLNAProtocolTests.swift
│   │   ├── MPVControllerTests.swift
│   │   └── PluginManagerTests.swift
│   └── MacastUITests/
│       └── MacastUITests.swift
├── Resources/
│   ├── Images.xcassets/
│   │   └── MenuIcon.pdf
│   ├── PreferencesWindow.xib
│   └── AboutWindow.xib
├── Package.swift
├── .swiftlint.yml
├── .swiftformat
├── Project_Configuration.md
└── Macast_Swift_Rewrite_SPCE.md
```

## 7. 开发流程

### 7.1 代码提交流程

1. 创建特性分支：`git checkout -b feature/feature-name`
2. 编写代码并提交：`git commit -m "Add feature-name"`
3. 运行测试：`swift test`
4. 运行代码检查：`swiftlint && swiftformat .`
5. 推送分支：`git push origin feature/feature-name`
6. 创建Pull Request
7. 代码审查
8. 合并分支：`git merge feature/feature-name`

### 7.2 构建流程

1. 清理构建：`swift package clean`
2. 构建项目（debug版本）：`swift build`
3. 构建项目（release版本）：`swift build -c release`
4. 运行测试：`swift test`
5. 运行应用：`swift run`

### 7.3 打包流程

1. 构建release版本：`swift build -c release`
2. 创建应用目录结构：
   ```bash
   mkdir -p Macast.app/Contents/MacOS
   mkdir -p Macast.app/Contents/Resources
   mkdir -p Macast.app/Contents/Frameworks
   ```
3. 复制可执行文件：
   ```bash
   cp .build/release/Macast Macast.app/Contents/MacOS/
   ```
4. 创建Info.plist文件：
   ```bash
   cat > Macast.app/Contents/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Macast</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.Macast</string>
    <key>CFBundleName</key>
    <string>Macast</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
</dict>
</plist>
EOF
   ```
5. 复制资源文件：
   ```bash
   cp -R Resources/* Macast.app/Contents/Resources/
   ```
6. 复制依赖框架：
   ```bash
   # 复制动态库依赖（如果有）
   ```
7. 签名应用：
   ```bash
   codesign --deep --force --verify --verbose --sign "Your Name (Team ID)" Macast.app
   ```
8. 创建DMG安装包：
   ```bash
   hdiutil create -volname "Macast" -srcfolder "Macast.app" -ov -format UDZO Macast.dmg
   ```

### 7.4 发布流程

1. 更新版本号：在Package.swift和Info.plist中更新版本号
2. 运行所有测试：确保应用稳定
3. 构建release版本：`swift build -c release`
4. 打包应用：创建DMG安装包
5. 验证应用：`spctl --assess --verbose Macast.app`
6. 发布应用：上传到GitHub Releases或其他分发平台

## 8. 常用命令

```bash
# 创建项目
swift package init --type executable

# 添加依赖
swift package add [package-url]

# 更新依赖
swift package update

# 清理构建
swift package clean

# 构建项目（debug版本）
swift build

# 构建项目（release版本）
swift build -c release

# 运行项目
swift run

# 运行测试
swift test

# 代码风格检查
swiftlint

# 代码格式化
swiftformat .

# 创建应用包目录结构
mkdir -p Macast.app/Contents/{MacOS,Resources,Frameworks}

# 签名应用
codesign --deep --force --verify --verbose --sign "Your Name (Team ID)" Macast.app

# 验证应用签名
codesign --verify --verbose Macast.app

# 检查应用是否可以运行
spctl --assess --verbose Macast.app

# 创建DMG安装包
hdiutil create -volname "Macast" -srcfolder "Macast.app" -ov -format UDZO Macast.dmg
```

## 9. 故障排除

### 9.1 依赖问题

```bash
# 清除依赖缓存
rm -rf .build
swift package update
```

### 9.2 代码检查问题

```bash
# 自动修复代码风格问题
swiftlint --fix
swiftformat .
```

### 9.3 构建问题

```bash
# 清理构建缓存
rm -rf .build
swift package clean

# 检查签名配置
codesign -dv --verbose=4 Macast.app

# 检查应用是否可以运行
spctl --assess --verbose Macast.app
```

## 10. 学习资源

### 10.1 Swift文档

- [Swift官方文档](https://docs.swift.org/swift-book/)
- [Swift API参考](https://developer.apple.com/documentation/swift)

### 10.2 macOS开发文档

- [macOS开发指南](https://developer.apple.com/macos/)
- [AppKit文档](https://developer.apple.com/documentation/appkit)
- [Network.framework文档](https://developer.apple.com/documentation/network)

### 10.3 DLNA协议文档

- [DLNA 1.5规范](https://www.dlna.org/standards/)
- [UPnP设备架构](https://openconnectivity.org/upnp-specs/upnp/UPnP-arch-DeviceArchitecture-v2.0-20201218.pdf)

### 10.4 播放器文档

- [MPV文档](https://mpv.io/manual/master/)
- [IINA文档](https://iina.io/documentation/)
