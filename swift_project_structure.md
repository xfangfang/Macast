# macOS平台Macast Swift项目结构设计

## 1. 项目概览

该项目是一个使用Swift开发的macOS平台DLNA媒体渲染器应用，基于原生macOS框架，提供良好的系统集成和用户体验。

## 2. 项目结构

### 整体结构
```
MacastSwift/
├── MacastSwift.xcodeproj/           # Xcode项目文件
├── Package.swift                    # Swift Package Manager配置
├── Sources/
│   ├── MacastSwift/                 # 主应用模块
│   ├── DLNA/                        # DLNA协议实现
│   ├── SSDP/                        # SSDP服务发现
│   ├── HTTPServer/                  # HTTP服务器
│   ├── MPV/                         # MPV播放器集成
│   └── Utilities/                   # 工具类
├── Tests/                           # 测试文件
├── Resources/                       # 资源文件
└── Documentation/                   # 文档
```

### 详细模块结构

#### 2.1 MacastSwift (主应用模块)
```
MacastSwift/
├── AppDelegate.swift                # 应用入口点
├── StatusMenuController.swift       # 菜单栏控制器
├── PreferencesWindowController.swift # 偏好设置窗口
├── AboutWindowController.swift      # 关于窗口
├── Assets.xcassets                  # 图像资源
└── Localizable.strings              # 本地化字符串
```

**职责**：
- 应用生命周期管理
- 用户界面实现
- 系统集成（菜单栏、通知、开机自启等）
- 协调各模块工作

#### 2.2 DLNA (DLNA协议实现)
```
DLNA/
├── DLNAProtocol.swift               # DLNA协议主类
├── DLNAService.swift                # DLNA服务基类
├── AVTransportService.swift         # AVTransport服务实现
├── RenderingControlService.swift    # RenderingControl服务实现
├── ConnectionManagerService.swift   # ConnectionManager服务实现
├── SOAPMessage.swift                # SOAP消息处理
├── XMLParser.swift                  # XML解析和生成
└── DLNAConstants.swift              # DLNA常量定义
```

**职责**：
- 实现DLNA/UPnP协议
- 处理SOAP消息
- 管理DLNA服务状态
- 与渲染器（如MPV）交互

#### 2.3 SSDP (SSDP服务发现)
```
SSDP/
├── SSDPServer.swift                 # SSDP服务器实现
├── SSDPMessage.swift                # SSDP消息处理
└── SSDPConstants.swift              # SSDP常量定义
```

**职责**：
- 实现SSDP服务发现协议
- 发送和接收SSDP多播消息
- 处理设备搜索和通知

#### 2.4 HTTPServer (HTTP服务器)
```
HTTPServer/
├── HTTPServer.swift                 # HTTP服务器实现
├── HTTPRequest.swift                # HTTP请求处理
├── HTTPResponse.swift               # HTTP响应生成
└── HTTPRoutes.swift                 # HTTP路由管理
```

**职责**：
- 实现轻量级HTTP服务器
- 处理DLNA HTTP请求
- 提供Web界面（如果需要）

#### 2.5 MPV (MPV播放器集成)
```
MPV/
├── MPVController.swift              # MPV控制器
├── MPVCommand.swift                 # MPV命令定义
├── MPVEvent.swift                   # MPV事件处理
└── MPVSocket.swift                  # MPV IPC socket通信
```

**职责**：
- 与MPV播放器交互
- 发送命令控制播放器
- 处理播放器事件
- 管理播放器状态

#### 2.6 Utilities (工具类)
```
Utilities/
├── Settings.swift                   # 设置管理
├── Logging.swift                    # 日志记录
├── NetworkUtils.swift               # 网络工具
├── FileUtils.swift                  # 文件工具
└── SystemUtils.swift                # 系统工具
```

**职责**：
- 提供通用工具函数
- 管理应用设置
- 处理日志记录
- 提供网络和系统相关功能

## 3. 关键文件内容示例

### 3.1 AppDelegate.swift
```swift
import Cocoa
import ServiceManagement

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusMenuController: StatusMenuController?
    var ssdpServer: SSDPServer?
    var httpServer: HTTPServer?
    var mpvController: MPVController?
    var dlnaProtocol: DLNAProtocol?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 初始化日志
        Logging.setup()
        
        // 加载设置
        Settings.load()
        
        // 初始化MPV控制器
        mpvController = MPVController()
        
        // 初始化DLNA协议
        dlnaProtocol = DLNAProtocol(renderer: mpvController!)
        
        // 初始化HTTP服务器
        httpServer = HTTPServer(port: Settings.port)
        httpServer?.setDLNAProtocol(dlnaProtocol!)
        
        // 初始化SSDP服务器
        ssdpServer = SSDPServer(httpServer: httpServer!)
        
        // 初始化菜单栏控制器
        statusMenuController = StatusMenuController()
        statusMenuController?.setup()
        
        // 启动服务
        if Settings.startAtLogin {
            startServices()
        }
        
        // 设置开机自启
        updateStartAtLogin()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // 停止所有服务
        stopServices()
        
        // 保存设置
        Settings.save()
    }
    
    func startServices() {
        do {
            try httpServer?.start()
            ssdpServer?.start()
            mpvController?.start()
            Settings.isServiceRunning = true
        } catch {
            Logging.error("Failed to start services: \(error)")
            showNotification(title: "Macast", subtitle: "Failed to start services")
        }
    }
    
    func stopServices() {
        httpServer?.stop()
        ssdpServer?.stop()
        mpvController?.stop()
        Settings.isServiceRunning = false
    }
    
    func updateStartAtLogin() {
        let launcherAppID = "com.yourcompany.MacastSwiftLauncher"
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == launcherAppID }.isEmpty
        
        if Settings.startAtLogin {
            if !isRunning {
                SMLoginItemSetEnabled(launcherAppID as CFString, true)
            }
        } else {
            SMLoginItemSetEnabled(launcherAppID as CFString, false)
        }
    }
    
    func showNotification(title: String, subtitle: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.subtitle = subtitle
        NSUserNotificationCenter.default.deliver(notification)
    }
}
```

### 3.2 StatusMenuController.swift
```swift
import Cocoa

class StatusMenuController: NSObject {
    
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var toggleServiceMenuItem: NSMenuItem!
    @IBOutlet weak var ipAddressMenuItem: NSMenuItem!
    @IBOutlet weak var startAtLoginMenuItem: NSMenuItem!
    
    private var statusItem: NSStatusItem!
    private var preferencesWindow: PreferencesWindowController?
    private var aboutWindow: AboutWindowController?
    
    func setup() {
        // 创建状态栏项
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem.button {
            button.image = NSImage(named: "MenuIcon")
            button.imagePosition = .imageOnly
            button.toolTip = "Macast"
        }
        
        // 设置菜单
        statusItem.menu = statusMenu
        
        // 初始化窗口
        preferencesWindow = PreferencesWindowController(windowNibName: "PreferencesWindow")
        aboutWindow = AboutWindowController(windowNibName: "AboutWindow")
        
        // 更新菜单项状态
        updateMenuItems()
        
        // 监听设置变化
        NotificationCenter.default.addObserver(self, selector: #selector(settingsChanged), name: .settingsChanged, object: nil)
    }
    
    @objc func updateMenuItems() {
        // 更新服务状态菜单项
        if Settings.isServiceRunning {
            toggleServiceMenuItem.title = "Stop Cast"
        } else {
            toggleServiceMenuItem.title = "Start Cast"
        }
        
        // 更新IP地址菜单项
        let ipAddresses = NetworkUtils.getIPAddresses()
        if !ipAddresses.isEmpty {
            ipAddressMenuItem.title = ipAddresses.joined(separator: "/") + ":\(Settings.port)"
            ipAddressMenuItem.isEnabled = true
        } else {
            ipAddressMenuItem.title = "No network connection"
            ipAddressMenuItem.isEnabled = false
        }
        
        // 更新开机自启菜单项
        startAtLoginMenuItem.state = Settings.startAtLogin ? .on : .off
    }
    
    @IBAction func toggleService(_ sender: NSMenuItem) {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        
        if Settings.isServiceRunning {
            appDelegate.stopServices()
        } else {
            appDelegate.startServices()
        }
        
        updateMenuItems()
    }
    
    @IBAction func showPreferences(_ sender: NSMenuItem) {
        preferencesWindow?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @IBAction func showAbout(_ sender: NSMenuItem) {
        aboutWindow?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @IBAction func toggleStartAtLogin(_ sender: NSMenuItem) {
        Settings.startAtLogin = !Settings.startAtLogin
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.updateStartAtLogin()
        updateMenuItems()
    }
    
    @IBAction func quit(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
    @objc func settingsChanged() {
        updateMenuItems()
    }
}
```

### 3.3 DLNAProtocol.swift
```swift
import Foundation

protocol DLNARenderer {
    func play(url: URL)
    func pause()
    func resume()
    func stop()
    func seek(to position: String) // position format: "HH:MM:SS"
    func setVolume(_ volume: Int) // 0-100
    func setMute(_ mute: Bool)
}

class DLNAProtocol {
    private let renderer: DLNARenderer
    private var services: [String: DLNAService]
    private var state: [String: Any]
    
    init(renderer: DLNARenderer) {
        self.renderer = renderer
        self.services = [:]
        self.state = [:]
        
        // 初始化服务
        initializeServices()
        
        // 设置默认状态
        initializeDefaultState()
    }
    
    private func initializeServices() {
        let avTransport = AVTransportService(renderer: renderer)
        let renderingControl = RenderingControlService(renderer: renderer)
        let connectionManager = ConnectionManagerService()
        
        services["AVTransport"] = avTransport
        services["RenderingControl"] = renderingControl
        services["ConnectionManager"] = connectionManager
    }
    
    private func initializeDefaultState() {
        state["TransportState"] = "STOPPED"
        state["TransportStatus"] = "OK"
        state["Volume"] = 80
        state["Mute"] = false
        state["CurrentTrackDuration"] = "00:00:00"
        state["CurrentTrackURI"] = ""
        state["CurrentTrackTitle"] = ""
    }
    
    func handleSOAPRequest(_ request: SOAPMessage) -> SOAPMessage {
        guard let service = services[request.service] else {
            return SOAPMessage.errorResponse(for: request)
        }
        
        return service.handleAction(request.action, parameters: request.parameters)
    }
    
    func getState(_ stateName: String) -> Any? {
        return state[stateName]
    }
    
    func setState(_ stateName: String, value: Any) {
        state[stateName] = value
        // 通知订阅者状态变化
        notifyStateChange(stateName, value: value)
    }
    
    private func notifyStateChange(_ stateName: String, value: Any) {
        // 实现状态变化通知逻辑
    }
}
```

### 3.4 MPVController.swift
```swift
import Foundation

class MPVController: DLNARenderer {
    private var process: Process?
    private var socketPath: String
    private var socket: Socket?
    private var isRunning: Bool = false
    private let queue = DispatchQueue(label: "com.yourcompany.MPVController")
    
    init() {
        // 生成随机socket路径
        socketPath = "/tmp/macast_mpvsocket\(Int.random(in: 0...9999))"
    }
    
    func start() {
        guard !isRunning else { return }
        
        queue.async {
            self.launchMPV()
            self.connectToSocket()
            self.isRunning = true
        }
    }
    
    func stop() {
        guard isRunning else { return }
        
        queue.async {
            self.sendCommand(["quit"])
            self.socket?.close()
            self.process?.terminate()
            self.process = nil
            self.isRunning = false
        }
    }
    
    private func launchMPV() {
        process = Process()
        process?.executableURL = URL(fileURLWithPath: Settings.mpvPath)
        process?.arguments = [
            "--input-ipc-server=\(socketPath)",
            "--idle=yes",
            "--no-terminal",
            "--hwdec=yes",
            "--autofit=80%",
            "--ontop"
        ]
        
        do {
            try process?.run()
            Logging.info("MPV started successfully")
        } catch {
            Logging.error("Failed to start MPV: \(error)")
            // 显示错误通知
        }
    }
    
    private func connectToSocket() {
        // 等待MPV启动并创建socket
        Thread.sleep(forTimeInterval: 1)
        
        socket = Socket(path: socketPath)
        do {
            try socket?.connect()
            Logging.info("Connected to MPV socket")
            
            // 开始监听MPV事件
            listenForEvents()
        } catch {
            Logging.error("Failed to connect to MPV socket: \(error)")
        }
    }
    
    private func listenForEvents() {
        queue.async {
            while self.isRunning {
                if let response = try? self.socket?.receive() {
                    self.handleMPVResponse(response)
                }
            }
        }
    }
    
    private func handleMPVResponse(_ response: String) {
        // 解析MPV响应并更新状态
        Logging.debug("MPV response: \(response)")
        
        // 示例：处理播放结束事件
        if response.contains("\"event\":\"end-file\"") {
            let appDelegate = NSApplication.shared.delegate as! AppDelegate
            appDelegate.dlnaProtocol?.setState("TransportState", value: "STOPPED")
        }
    }
    
    private func sendCommand(_ command: [String]) {
        guard isRunning else { return }
        
        let commandJSON = ["command": command]
        do {
            let data = try JSONSerialization.data(withJSONObject: commandJSON)
            if let commandString = String(data: data, encoding: .utf8) {
                try socket?.send("\(commandString)\n")
                Logging.debug("Sent command: \(command)")
            }
        } catch {
            Logging.error("Failed to send command: \(error)")
        }
    }
    
    // MARK: - DLNARenderer Protocol
    
    func play(url: URL) {
        sendCommand(["loadfile", url.absoluteString])
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.dlnaProtocol?.setState("TransportState", value: "PLAYING")
        appDelegate.dlnaProtocol?.setState("CurrentTrackURI", value: url.absoluteString)
    }
    
    func pause() {
        sendCommand(["set_property", "pause", true])
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.dlnaProtocol?.setState("TransportState", value: "PAUSED_PLAYBACK")
    }
    
    func resume() {
        sendCommand(["set_property", "pause", false])
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.dlnaProtocol?.setState("TransportState", value: "PLAYING")
    }
    
    func stop() {
        sendCommand(["stop"])
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.dlnaProtocol?.setState("TransportState", value: "STOPPED")
    }
    
    func seek(to position: String) {
        sendCommand(["seek", position, "absolute"])
    }
    
    func setVolume(_ volume: Int) {
        sendCommand(["set_property", "volume", volume])
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.dlnaProtocol?.setState("Volume", value: volume)
    }
    
    func setMute(_ mute: Bool) {
        sendCommand(["set_property", "mute", mute])
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.dlnaProtocol?.setState("Mute", value: mute)
    }
}
```

## 4. 关键技术和框架

### 4.1 核心框架
- **AppKit**：用于构建macOS用户界面
- **Network.framework**：用于网络通信
- **Foundation**：基础功能支持
- **ServiceManagement.framework**：实现开机自启
- **UserNotifications.framework**：发送系统通知

### 4.2 第三方库
- **XMLCoder**：XML序列化和反序列化
- **SwiftLog**：日志记录

## 5. 构建和部署

### 5.1 构建要求
- Xcode 15.0+
- Swift 5.9+
- macOS 13.0+

### 5.2 依赖管理
使用Swift Package Manager管理依赖：

```swift
// Package.swift
i mport PackageDescription

let package = Package(
    name: "MacastSwift",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MacastSwift", targets: ["MacastSwift"])
    ],
    dependencies: [
        .package(url: "https://github.com/CoreOffice/XMLCoder.git", from: "0.17.1"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.3")
    ],
    targets: [
        .executableTarget(
            name: "MacastSwift",
            dependencies: ["DLNA", "SSDP", "HTTPServer", "MPV", "Utilities"],
            resources: [
                .process("Resources/"),
                .copy("Localizable.strings")
            ]
        ),
        .target(
            name: "DLNA",
            dependencies: ["Utilities"],
            path: "Sources/DLNA"
        ),
        .target(
            name: "SSDP",
            dependencies: ["Utilities"],
            path: "Sources/SSDP"
        ),
        .target(
            name: "HTTPServer",
            dependencies: ["Utilities"],
            path: "Sources/HTTPServer"
        ),
        .target(
            name: "MPV",
            dependencies: ["Utilities"],
            path: "Sources/MPV"
        ),
        .target(
            name: "Utilities",
            dependencies: [
                .product(name: "XMLCoder", package: "XMLCoder"),
                .product(name: "Logging", package: "swift-log")
            ],
            path: "Sources/Utilities"
        ),
        .testTarget(
            name: "MacastSwiftTests",
            dependencies: ["MacastSwift"]
        )
    ]
)
```

## 6. 开发流程

1. **需求分析**：明确功能需求和技术要求
2. **架构设计**：设计项目结构和各模块关系
3. **模块开发**：按模块进行开发和测试
4. **集成测试**：集成各模块并进行测试
5. **用户体验优化**：优化界面和交互
6. **打包发布**：生成应用包并发布

## 7. 总结

该项目结构设计清晰，模块划分合理，充分利用了Swift和macOS的优势，为开发一个高性能、易用的DLNA媒体渲染器应用提供了良好的基础。通过模块化设计，便于维护和扩展，可以根据需要添加新功能或支持其他播放器。