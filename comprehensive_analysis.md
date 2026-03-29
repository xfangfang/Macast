# Macast macOS平台Swift重写全面分析报告

## 1. 项目概述与可行性分析

### 1.1 项目概述
Macast是一个基于Python的DLNA媒体渲染器应用程序，允许用户从移动设备将视频、图片或音乐推送到计算机。主要功能包括：
- DLNA/UPnP协议支持
- SSDP服务发现
- MPV播放器集成
- 菜单栏/任务栏应用程序界面
- 插件系统支持第三方播放器
- 跨平台支持（MacOS、Windows、Linux）

### 1.2 核心组件
1. **macast.py**：主应用程序类，处理GUI和插件管理
2. **protocol.py**：DLNA协议实现
3. **renderer.py**：媒体渲染器基类
4. **ssdp.py**：SSDP服务发现实现
5. **server.py**：HTTP服务器实现，处理DLNA请求
6. **mpv.py**：MPV播放器集成实现

### 1.3 Swift重写优势
1. **性能更好**：Swift在处理并发和网络操作时性能优于Python
2. **更好的Apple生态系统集成**：特别是在macOS平台上
3. **更高效的内存管理**：自动引用计数
4. **类型安全**：减少运行时错误
5. **现代编程语言特性**：如闭包、泛型、协议等

### 1.4 技术栈对比
| 技术 | Python版本 | Swift版本 |
|------|------------|-----------|
| 网络 | CherryPy + socket | Network.framework + URLSession |
| GUI | pystray | AppKit/SwiftUI |
| 播放器集成 | subprocess | Process |
| 数据处理 | XML/Soap | XMLDocument/JSONSerialization |
| 系统集成 | platform-specific modules | macOS frameworks (ServiceManagement, UserNotifications) |

## 2. macOS平台特有技术栈和框架

### 2.1 GUI框架
- **AppKit**：传统的macOS UI框架，功能强大，特别适合菜单栏应用开发
- **SwiftUI**：现代声明式UI框架，开发效率高，但某些系统集成功能可能不够完善
- **NSStatusItem**：用于创建菜单栏图标和菜单

### 2.2 网络框架
- **Network.framework**：Apple官方的现代网络框架，支持多播、Bonjour、WebSocket等，非常适合实现DLNA和SSDP协议
- **URLSession**：用于HTTP请求，可替代CherryPy

### 2.3 系统集成
- **ServiceManagement.framework**：实现开机自启功能
- **UserNotifications.framework**：发送系统通知
- **NSWorkspace**：打开文件、URL，获取系统信息
- **Process**：调用外部进程（如MPV播放器）
- **SystemConfiguration.framework**：获取网络配置和IP地址

### 2.4 数据处理
- **XMLDocument**：解析和生成XML（用于DLNA的SOAP消息）
- **JSONSerialization**：处理JSON数据
- **PropertyListSerialization**：处理plist配置文件

## 3. 核心组件实现方案

### 3.1 GUI组件实现

#### 3.1.1 菜单栏应用实现

```swift
class StatusMenuController {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var toggleMenuItem: NSMenuItem!
    private var preferencesMenuItem: NSMenuItem!
    private var quitMenuItem: NSMenuItem!
    private var ipAddressMenuItem: NSMenuItem!
    private var startAtLoginMenuItem: NSMenuItem!
    
    func setup() {
        // 创建状态栏项
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem.button {
            // 设置图标
            let icon = NSImage(named: "MenuIcon")
            icon?.isTemplate = true // 支持深色模式
            button.image = icon
            button.imagePosition = .imageOnly
            button.toolTip = "Macast"
        }
        
        // 创建菜单
        menu = NSMenu(title: "Macast")
        
        // 添加菜单项
        toggleMenuItem = NSMenuItem(title: "Start Cast", action: #selector(toggleService), keyEquivalent: "p")
        menu.addItem(toggleMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        ipAddressMenuItem = NSMenuItem(title: "IP Address", action: nil, keyEquivalent: "")
        ipAddressMenuItem.isEnabled = false
        menu.addItem(ipAddressMenuItem)
        
        startAtLoginMenuItem = NSMenuItem(title: "Start at Login", action: #selector(toggleStartAtLogin), keyEquivalent: "l")
        startAtLoginMenuItem.state = .off
        menu.addItem(startAtLoginMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        preferencesMenuItem = NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ",")
        menu.addItem(preferencesMenuItem)
        
        let aboutMenuItem = NSMenuItem(title: "About Macast", action: #selector(showAbout), keyEquivalent: "a")
        menu.addItem(aboutMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        quitMenuItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        menu.addItem(quitMenuItem)
        
        // 设置菜单
        statusItem.menu = menu
        
        // 更新IP地址
        updateIPAddress()
        
        // 监听网络变化
        setupNetworkMonitoring()
    }
    
    @objc private func toggleService() {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        if Settings.isServiceRunning {
            appDelegate.stopServices()
            toggleMenuItem.title = "Start Cast"
        } else {
            appDelegate.startServices()
            toggleMenuItem.title = "Stop Cast"
        }
    }
    
    @objc private func showPreferences() {
        // 显示偏好设置窗口
        let windowController = PreferencesWindowController(windowNibName: "PreferencesWindow")
        windowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func showAbout() {
        // 显示关于窗口
        let windowController = AboutWindowController(windowNibName: "AboutWindow")
        windowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(self)
    }
    
    @objc private func toggleStartAtLogin() {
        Settings.startAtLogin = !Settings.startAtLogin
        startAtLoginMenuItem.state = Settings.startAtLogin ? .on : .off
        
        // 更新开机自启设置
        let launcherAppID = "com.yourcompany.MacastSwiftLauncher"
        SMLoginItemSetEnabled(launcherAppID as CFString, Settings.startAtLogin)
    }
    
    private func updateIPAddress() {
        let ipAddresses = NetworkUtils.getIPAddresses()
        if !ipAddresses.isEmpty {
            ipAddressMenuItem.title = "IP: \(ipAddresses.joined(separator: "/")): \(Settings.port)"
        } else {
            ipAddressMenuItem.title = "No network connection"
        }
    }
    
    private func setupNetworkMonitoring() {
        // 使用SystemConfiguration.framework监听网络变化
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateIPAddress()
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
}
```

#### 3.1.2 偏好设置窗口

```swift
class PreferencesWindowController: NSWindowController, NSWindowDelegate {
    @IBOutlet weak var mpvPathTextField: NSTextField!
    @IBOutlet weak var portTextField: NSTextField!
    @IBOutlet weak var friendlyNameTextField: NSTextField!
    @IBOutlet weak var playerSizePopup: NSPopUpButton!
    @IBOutlet weak var playerPositionPopup: NSPopUpButton!
    @IBOutlet weak var hardwareDecodeCheckbox: NSButton!
    
    convenience init() {
        self.init(windowNibName: "PreferencesWindow")
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // 设置窗口代理
        window?.delegate = self
        
        // 加载设置
        loadSettings()
    }
    
    private func loadSettings() {
        mpvPathTextField.stringValue = Settings.mpvPath
        portTextField.stringValue = String(Settings.port)
        friendlyNameTextField.stringValue = Settings.friendlyName
        
        // 设置播放器大小
        playerSizePopup.selectItem(at: Settings.playerSize.rawValue)
        
        // 设置播放器位置
        playerPositionPopup.selectItem(at: Settings.playerPosition.rawValue)
        
        // 设置硬件解码
        hardwareDecodeCheckbox.state = Settings.hardwareDecode ? .on : .off
    }
    
    private func saveSettings() {
        Settings.mpvPath = mpvPathTextField.stringValue
        Settings.port = Int(portTextField.stringValue) ?? 8008
        Settings.friendlyName = friendlyNameTextField.stringValue
        Settings.playerSize = PlayerSize(rawValue: playerSizePopup.indexOfSelectedItem) ?? .normal
        Settings.playerPosition = PlayerPosition(rawValue: playerPositionPopup.indexOfSelectedItem) ?? .rightTop
        Settings.hardwareDecode = hardwareDecodeCheckbox.state == .on
        
        // 保存到UserDefaults
        Settings.save()
        
        // 通知其他组件设置已更改
        NotificationCenter.default.post(name: .settingsChanged, object: nil)
    }
    
    // MARK: - NSWindowDelegate
    
    func windowWillClose(_ notification: Notification) {
        // 保存设置
        saveSettings()
    }
    
    @IBAction func browseMPVPath(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select MPV Executable"
        openPanel.allowedContentTypes = [.executable, .unixExecutable]
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        
        openPanel.beginSheetModal(for: window!) { [weak self] result in
            if result == .OK, let url = openPanel.url {
                self?.mpvPathTextField.stringValue = url.path
            }
        }
    }
}
```

### 3.2 网络组件实现

#### 3.2.1 SSDP服务实现

```swift
class SSDPServer {
    private var listener: NWListener?
    private var multicastGroup: NWMulticastGroup?
    private var connection: NWConnection?
    private let httpServer: HTTPServer
    
    init(httpServer: HTTPServer) {
        self.httpServer = httpServer
    }
    
    func start() async throws {
        // 创建多播组（SSDP使用239.255.255.250:1900）
        let multicastEndpoint = NWEndpoint.hostPort(host: "239.255.255.250", port: 1900)
        multicastGroup = try NWMulticastGroup(for: [multicastEndpoint])
        
        // 设置接收处理
        multicastGroup?.setReceiveHandler(maximumMessageSize: 8192) { [weak self] message, content, isComplete in
            guard let self = self, let content = content else { return }
            
            Task { 
                await self.handleSSDPMessage(content)
            }
        }
        
        // 加入多播组
        let queue = DispatchQueue(label: "SSDPQueue")
        try await multicastGroup?.join(queue: queue)
        
        Logging.info("SSDP server started")
        
        // 发送ALIVE通知
        await sendAliveNotification()
    }
    
    func stop() {
        // 发送BYEBYE通知
        Task { 
            await sendByeByeNotification()
        }
        
        // 离开多播组
        multicastGroup?.leave()
        
        Logging.info("SSDP server stopped")
    }
    
    private func handleSSDPMessage(_ data: Data) async {
        guard let message = String(data: data, encoding: .utf8) else { return }
        
        Logging.debug("Received SSDP message: \(message)")
        
        // 解析SSDP消息
        if message.starts(with: "M-SEARCH") {
            // 处理搜索请求
            await handleSearchRequest(message)
        }
    }
    
    private func handleSearchRequest(_ message: String) async {
        // 解析搜索目标
        let lines = message.split(separator: "\r\n")
        guard let stLine = lines.first(where: { $0.hasPrefix("ST:") }),
              let mxLine = lines.first(where: { $0.hasPrefix("MX:") }) else {
            return
        }
        
        let searchTarget = String(stLine.dropFirst(3).trimmingCharacters(in: .whitespaces))
        let maxDelay = Double(String(mxLine.dropFirst(3).trimmingCharacters(in: .whitespaces))) ?? 1.0
        
        // 检查是否匹配我们的服务类型
        let ourServiceTypes = [
            "upnp:rootdevice",
            "urn:schemas-upnp-org:device:MediaRenderer:1",
            "urn:schemas-upnp-org:service:AVTransport:1",
            "urn:schemas-upnp-org:service:RenderingControl:1",
            "urn:schemas-upnp-org:service:ConnectionManager:1"
        ]
        
        if searchTarget == "ssdp:all" || ourServiceTypes.contains(searchTarget) {
            // 随机延迟发送响应
            let delay = TimeInterval.random(in: 0...maxDelay)
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            // 发送响应
            await sendSearchResponse(searchTarget: searchTarget)
        }
    }
    
    private func sendSearchResponse(searchTarget: String) async {
        // 获取IP地址
        guard let ipAddress = NetworkUtils.getIPAddresses().first else { return }
        
        // 构建响应消息
        let response = [
            "HTTP/1.1 200 OK",
            "CACHE-CONTROL: max-age=1800",
            "DATE: \(DateFormatter.rfc1123.string(from: Date()))",
            "EXT:",
            "LOCATION: http://\(ipAddress):\(httpServer.port)/description.xml",
            "SERVER: MacOS/13.0, UPnP/1.1, Macast/1.0",
            "ST: \(searchTarget)",
            "USN: uuid:\(Settings.uuid)::\(searchTarget)"
        ].joined(separator: "\r\n") + "\r\n\r\n"
        
        // 发送响应（这里需要实现UDP响应发送逻辑）
        // 使用NWConnection发送UDP响应
    }
    
    private func sendAliveNotification() async {
        // 实现SSDP ALIVE通知发送
    }
    
    private func sendByeByeNotification() async {
        // 实现SSDP BYEBYE通知发送
    }
}

// 扩展DateFormatter以支持RFC1123格式
extension DateFormatter {
    static let rfc1123: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        return formatter
    }()
}
```

#### 3.2.2 HTTP服务器实现

```swift
class HTTPServer {
    private let port: Int
    private var listener: NWListener?
    private var dlnaProtocol: DLNAProtocol?
    
    var isRunning: Bool { listener != nil }
    
    init(port: Int) {
        self.port = port
    }
    
    func setDLNAProtocol(_ protocol: DLNAProtocol) {
        self.dlnaProtocol = protocol
    }
    
    func start() throws {
        // 创建监听器
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        
        listener = try NWListener(using: parameters, on: NWEndpoint.Port(integerLiteral: UInt16(port)))
        
        // 设置新连接处理
        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleNewConnection(connection)
        }
        
        // 设置状态变化处理
        listener?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                Logging.info("HTTP server started on port \(self.port)")
            case .failed(let error):
                Logging.error("HTTP server failed: \(error)")
            case .cancelled:
                Logging.info("HTTP server stopped")
            default:
                break
            }
        }
        
        // 开始监听
        listener?.start(queue: .main)
    }
    
    func stop() {
        listener?.cancel()
        listener = nil
    }
    
    private func handleNewConnection(_ connection: NWConnection) {
        // 接收数据
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let error = error {
                Logging.error("Connection error: \(error)")
                connection.cancel()
                return
            }
            
            if let data = data {
                // 处理HTTP请求
                self?.handleRequest(data: data, connection: connection)
            }
            
            if isComplete {
                connection.cancel()
            } else {
                // 继续接收数据
                connection.receive(minimumIncompleteLength: 1, maximumLength: 65536, completion: self?.handleReceive(_:_:_:_:))
            }
        }
        
        // 启动连接
        connection.start(queue: .main)
    }
    
    private func handleRequest(data: Data, connection: NWConnection) {
        guard let request = HTTPRequest(data: data) else {
            sendResponse(connection: connection, statusCode: 400, body: "Bad Request".data(using: .utf8))
            return
        }
        
        Logging.debug("HTTP Request: \(request.method) \(request.path)")
        
        // 路由处理
        switch request.path {
        case "/description.xml":
            handleDescriptionRequest(connection: connection)
        case "/dlna/AVTransport/action":
        case "/dlna/RenderingControl/action":
        case "/dlna/ConnectionManager/action":
            handleSOAPRequest(connection: connection, request: request)
        case "/assets/":
            handleAssetsRequest(connection: connection, request: request)
        case "/api/":
            handleAPIRequest(connection: connection, request: request)
        default:
            sendResponse(connection: connection, statusCode: 404, body: "Not Found".data(using: .utf8))
        }
    }
    
    private func handleDescriptionRequest(connection: NWConnection) {
        guard let ipAddress = NetworkUtils.getIPAddresses().first else { return }
        
        // 构建设备描述XML
        let description = String(format: "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<root xmlns=\"urn:schemas-upnp-org:device-1-0\">\n  <specVersion>\n    <major>1</major>\n    <minor>0</minor>\n  </specVersion>\n  <device>\n    <deviceType>urn:schemas-upnp-org:device:MediaRenderer:1</deviceType>\n    <friendlyName>%@</friendlyName>\n    <manufacturer>Macast</manufacturer>\n    <manufacturerURL>https://github.com/xfangfang/Macast</manufacturerURL>\n    <modelDescription>AVTransport Media Renderer</modelDescription>\n    <modelName>Macast</modelName>\n    <modelURL>https://xfangfang.github.io/Macast</modelURL>\n    <modelNumber>%@</modelNumber>\n    <serialNumber>1024</serialNumber>\n    <UDN>uuid:%@</UDN>\n    <serviceList>\n      <service>\n        <serviceType>urn:schemas-upnp-org:service:ConnectionManager:1</serviceType>\n        <serviceId>urn:upnp-org:serviceId:ConnectionManager</serviceId>\n        <SCPDURL>/dlna/ConnectionManager.xml</SCPDURL>\n        <controlURL>/dlna/ConnectionManager/action</controlURL>\n        <eventSubURL>/dlna/ConnectionManager/event</eventSubURL>\n      </service>\n      <service>\n        <serviceType>urn:schemas-upnp-org:service:AVTransport:1</serviceType>\n        <serviceId>urn:upnp-org:serviceId:AVTransport</serviceId>\n        <SCPDURL>/dlna/AVTransport.xml</SCPDURL>\n        <controlURL>/dlna/AVTransport/action</controlURL>\n        <eventSubURL>/dlna/AVTransport/event</eventSubURL>\n      </service>\n      <service>\n        <serviceType>urn:schemas-upnp-org:service:RenderingControl:1</serviceType>\n        <serviceId>urn:upnp-org:serviceId:RenderingControl</serviceId>\n        <SCPDURL>/dlna/RenderingControl.xml</SCPDURL>\n        <controlURL>/dlna/RenderingControl/action</controlURL>\n        <eventSubURL>/dlna/RenderingControl/event</eventSubURL>\n      </service>\n    </serviceList>\n  </device>\n</root>", Settings.friendlyName, Settings.version, Settings.uuid)
        
        sendResponse(connection: connection, 
                   statusCode: 200, 
                   headers: ["Content-Type": "text/xml; charset=utf-8"], 
                   body: description.data(using: .utf8))
    }
    
    private func handleSOAPRequest(connection: NWConnection, request: HTTPRequest) {
        guard let dlnaProtocol = dlnaProtocol else {
            sendResponse(connection: connection, statusCode: 500, body: "Internal Server Error".data(using: .utf8))
            return
        }
        
        // 解析SOAP请求
        guard let soapRequest = SOAPMessage(data: request.body) else {
            sendResponse(connection: connection, statusCode: 400, body: "Invalid SOAP Request".data(using: .utf8))
            return
        }
        
        // 处理SOAP请求
        let soapResponse = dlnaProtocol.handleSOAPRequest(soapRequest)
        
        // 发送响应
        sendResponse(connection: connection, 
                   statusCode: 200, 
                   headers: ["Content-Type": "text/xml; charset=utf-8", "EXT": ""], 
                   body: soapResponse.data)
    }
    
    private func sendResponse(connection: NWConnection, statusCode: Int, headers: [String: String] = [:], body: Data?) {
        // 构建响应头
        var responseLines = ["HTTP/1.1 \(statusCode) \(HTTPResponse.statusText(for: statusCode))"]
        
        // 添加服务器信息
        responseLines.append("Server: MacOS/13.0, UPnP/1.1, Macast/1.0")
        
        // 添加内容长度
        if let body = body {
            responseLines.append("Content-Length: \(body.count)")
        } else {
            responseLines.append("Content-Length: 0")
        }
        
        // 添加用户定义的头
        for (key, value) in headers {
            responseLines.append("\(key): \(value)")
        }
        
        // 结束头
        responseLines.append("")
        
        // 构建响应数据
        var responseData = responseLines.joined(separator: "\r\n").data(using: .utf8) ?? Data()
        
        // 添加响应体
        if let body = body {
            responseData.append(body)
        }
        
        // 发送响应
        connection.send(content: responseData, completion: .contentProcessed { error in
            if let error = error {
                Logging.error("Failed to send response: \(error)")
            }
            connection.cancel()
        })
    }
    
    // 其他请求处理方法...
}

// HTTP请求结构体
struct HTTPRequest {
    let method: String
    let path: String
    let version: String
    let headers: [String: String]
    let body: Data
    
    init?(data: Data) {
        // 解析HTTP请求
        guard let requestString = String(data: data, encoding: .utf8) else { return nil }
        
        let lines = requestString.split(separator: "\r\n", omittingEmptySubsequences: false)
        guard lines.count >= 1 else { return nil }
        
        // 解析请求行
        let requestLine = lines[0].split(separator: " ")
        guard requestLine.count == 3 else { return nil }
        
        method = String(requestLine[0])
        path = String(requestLine[1])
        version = String(requestLine[2])
        
        // 解析头部
        var headers: [String: String] = [:]
        var bodyStartIndex = 0
        
        for (index, line) in lines.enumerated() {
            if index == 0 { continue } // 跳过请求行
            if line.isEmpty { // 头部结束
                bodyStartIndex = index + 1
                break
            }
            
            if let colonIndex = line.firstIndex(of: ":") {
                let key = String(line[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let value = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                headers[key] = value
            }
        }
        
        self.headers = headers
        
        // 解析请求体
        if bodyStartIndex < lines.count {
            let bodyString = lines[bodyStartIndex...].joined(separator: "\r\n")
            body = bodyString.data(using: .utf8) ?? Data()
        } else {
            body = Data()
        }
    }
}
```

### 3.3 DLNA协议实现

```swift
// DLNA服务基类
class DLNAService {
    func handleAction(_ action: String, parameters: [String: String]) -> SOAPMessage {
        // 默认实现，子类应重写
        return SOAPMessage.errorResponse(forAction: action)
    }
    
    func getState(_ stateName: String) -> Any? {
        // 默认实现，子类应重写
        return nil
    }
    
    func setState(_ stateName: String, value: Any) {
        // 默认实现，子类应重写
    }
}

// AVTransport服务
class AVTransportService: DLNAService {
    private let renderer: DLNARenderer
    
    init(renderer: DLNARenderer) {
        self.renderer = renderer
    }
    
    override func handleAction(_ action: String, parameters: [String: String]) -> SOAPMessage {
        switch action {
        case "SetAVTransportURI":
            return handleSetAVTransportURI(parameters)
        case "Play":
            return handlePlay(parameters)
        case "Pause":
            return handlePause(parameters)
        case "Stop":
            return handleStop(parameters)
        case "Seek":
            return handleSeek(parameters)
        case "GetPositionInfo":
            return handleGetPositionInfo(parameters)
        case "GetTransportInfo":
            return handleGetTransportInfo(parameters)
        default:
            return SOAPMessage.errorResponse(forAction: action)
        }
    }
    
    private func handleSetAVTransportURI(_ parameters: [String: String]) -> SOAPMessage {
        guard let uri = parameters["CurrentURI"] else {
            return SOAPMessage.errorResponse(forAction: "SetAVTransportURI")
        }
        
        // 解析元数据
        let title = parseTitleFromMetadata(parameters["CurrentURIMetaData"] ?? "")
        
        // 设置播放URI
        renderer.setMediaURL(uri, title: title)
        
        // 更新状态
        setState("CurrentTrackURI", value: uri)
        setState("CurrentTrackTitle", value: title)
        setState("TransportState", value: "PAUSED_PLAYBACK")
        
        return SOAPMessage.successResponse(forAction: "SetAVTransportURI")
    }
    
    private func handlePlay(_ parameters: [String: String]) -> SOAPMessage {
        renderer.setMediaResume()
        setState("TransportState", value: "PLAYING")
        return SOAPMessage.successResponse(forAction: "Play")
    }
    
    private func handlePause(_ parameters: [String: String]) -> SOAPMessage {
        renderer.setMediaPause()
        setState("TransportState", value: "PAUSED_PLAYBACK")
        return SOAPMessage.successResponse(forAction: "Pause")
    }
    
    private func handleStop(_ parameters: [String: String]) -> SOAPMessage {
        renderer.setMediaStop()
        setState("TransportState", value: "STOPPED")
        return SOAPMessage.successResponse(forAction: "Stop")
    }
    
    private func handleSeek(_ parameters: [String: String]) -> SOAPMessage {
        guard let target = parameters["Target"] else {
            return SOAPMessage.errorResponse(forAction: "Seek")
        }
        
        // 解析seek目标（格式：00:00:00）
        renderer.setMediaPosition(target)
        setState("RelativeTimePosition", value: target)
        setState("AbsoluteTimePosition", value: target)
        
        return SOAPMessage.successResponse(forAction: "Seek")
    }
    
    private func handleGetPositionInfo(_ parameters: [String: String]) -> SOAPMessage {
        var responseParameters: [String: String] = [
            "Track": "1",
            "TrackDuration": getState("CurrentTrackDuration") as? String ?? "00:00:00",
            "TrackMetaData": "",
            "TrackURI": getState("CurrentTrackURI") as? String ?? "",
            "RelTime": getState("RelativeTimePosition") as? String ?? "00:00:00",
            "AbsTime": getState("AbsoluteTimePosition") as? String ?? "00:00:00",
            "RelCount": "0",
            "AbsCount": "0"
        ]
        
        return SOAPMessage.response(forAction: "GetPositionInfo", parameters: responseParameters)
    }
    
    private func handleGetTransportInfo(_ parameters: [String: String]) -> SOAPMessage {
        var responseParameters: [String: String] = [
            "CurrentTransportState": getState("TransportState") as? String ?? "STOPPED",
            "CurrentTransportStatus": getState("TransportStatus") as? String ?? "OK",
            "CurrentSpeed": "1"
        ]
        
        return SOAPMessage.response(forAction: "GetTransportInfo", parameters: responseParameters)
    }
    
    private func parseTitleFromMetadata(_ metadata: String) -> String {
        // 解析DLNA元数据中的标题
        // 这里使用XMLDocument解析
        do {
            let xmlDoc = try XMLDocument(xmlString: metadata, options: [])
            let titleXPath = "//dc:title"
            let titleNodes = try xmlDoc.nodes(forXPath: titleXPath, namespaces: ["dc": "http://purl.org/dc/elements/1.1/"]) as! [XMLElement]
            
            if let titleNode = titleNodes.first {
                return titleNode.stringValue ?? ""
            }
        } catch {
            Logging.error("Failed to parse metadata: \(error)")
        }
        
        return ""
    }
}

// SOAP消息处理
class SOAPMessage {
    let service: String
    let action: String
    let parameters: [String: String]
    let data: Data
    
    init?(data: Data) {
        // 解析SOAP消息
        guard let xmlString = String(data: data, encoding: .utf8) else { return nil }
        
        do {
            let xmlDoc = try XMLDocument(xmlString: xmlString, options: [])
            
            // 解析命名空间
            let soapEnvNS = "http://schemas.xmlsoap.org/soap/envelope/"
            let soapNs = "urn:schemas-upnp-org:service:AVTransport:1"
            
            // 解析Body
            let bodyXPath = "//\(soapEnvNS):Body"
            guard let bodyNode = try xmlDoc.nodes(forXPath: bodyXPath, namespaces: ["env": soapEnvNS]).first as? XMLElement else {
                return nil
            }
            
            // 解析操作
            guard let actionNode = bodyNode.children?.first as? XMLElement else { return nil }
            
            let actionName = actionNode.name ?? ""
            let serviceName = actionName.split(separator: "_").first.map(String.init) ?? ""
            
            self.service = serviceName
            self.action = actionName
            
            // 解析参数
            var parameters: [String: String] = [:]
            for child in actionNode.children ?? [] {
                if let paramNode = child as? XMLElement {
                    parameters[paramNode.name ?? ""] = paramNode.stringValue
                }
            }
            
            self.parameters = parameters
            self.data = data
            
        } catch {
            Logging.error("Failed to parse SOAP message: \(error)")
            return nil
        }
    }
    
    // 生成响应
    static func response(forAction action: String, parameters: [String: String] = [:]) -> SOAPMessage {
        // 生成SOAP响应
        let soapEnvNS = "http://schemas.xmlsoap.org/soap/envelope/"
        let soapNs = "urn:schemas-upnp-org:service:AVTransport:1"
        
        let root = XMLElement(name: "Envelope", namespaceURI: soapEnvNS)
        root.addAttribute(XMLAttribute(name: "encodingStyle", stringValue: "http://schemas.xmlsoap.org/soap/encoding/"))
        
        let body = XMLElement(name: "Body", namespaceURI: soapEnvNS)
        root.addChild(body)
        
        let responseElement = XMLElement(name: "\(action)Response", namespaceURI: soapNs)
        body.addChild(responseElement)
        
        // 添加响应参数
        for (name, value) in parameters {
            let paramElement = XMLElement(name: name, stringValue: value)
            responseElement.addChild(paramElement)
        }
        
        let xmlDoc = XMLDocument(rootElement: root)
        xmlDoc.version = "1.0"
        xmlDoc.characterEncoding = "UTF-8"
        
        let data = xmlDoc.xmlData(options: [.nodePrettyPrint])
        
        // 创建响应对象
        return SOAPMessage(service: "", action: action, parameters: [:], data: data)
    }
    
    // 生成错误响应
    static func errorResponse(forAction action: String) -> SOAPMessage {
        // 生成SOAP响应
        let soapEnvNS = "http://schemas.xmlsoap.org/soap/envelope/"
        let soapNs = "urn:schemas-upnp-org:service:AVTransport:1"
        
        let root = XMLElement(name: "Envelope", namespaceURI: soapEnvNS)
        root.addAttribute(XMLAttribute(name: "encodingStyle", stringValue: "http://schemas.xmlsoap.org/soap/encoding/"))
        
        let body = XMLElement(name: "Body", namespaceURI: soapEnvNS)
        root.addChild(body)
        
        let faultElement = XMLElement(name: "Fault", namespaceURI: soapEnvNS)
        body.addChild(faultElement)
        
        // 创建错误节点
        let faultcode = XMLElement(name: "faultcode", stringValue: "soap:Client")
        let faultstring = XMLElement(name: "faultstring", stringValue: "Action not implemented")
        let detail = XMLElement(name: "detail")
        
        faultElement.addChildren([faultcode, faultstring, detail])
        
        let xmlDoc = XMLDocument(rootElement: root)
        xmlDoc.version = "1.0"
        xmlDoc.characterEncoding = "UTF-8"
        
        let data = xmlDoc.xmlData(options: [.nodePrettyPrint])
        
        // 创建响应对象
        return SOAPMessage(service: "", action: action, parameters: [:], data: data)
    }
    
    // 生成成功响应
    static func successResponse(forAction action: String) -> SOAPMessage {
        return response(forAction: action)
    }
    
    // 私有构造函数
    private init(service: String, action: String, parameters: [String: String], data: Data) {
        self.service = service
        self.action = action
        self.parameters = parameters
        self.data = data
    }
}
```

## 4. MPV播放器集成方案

### 4.1 集成方案选择

**推荐使用方案一：使用Process调用外部MPV**

理由：
1. 实现简单，降低开发难度和维护成本
2. 不依赖第三方Swift绑定库，减少兼容性问题
3. 与原始Macast实现方式一致，便于参考和迁移
4. 允许用户使用自己安装的MPV版本，灵活性高

### 4.2 核心实现代码

```swift
class MPVController {
    private var process: Process?
    private var socketPath: String
    private var socket: Socket?
    private var isRunning: Bool = false
    private var commandLock = NSLock()
    private let queue = DispatchQueue(label: "com.macast.mpv")
    
    // MPV状态回调
    var onPlayStateChange: ((Bool) -> Void)?
    var onPositionChange: ((String) -> Void)?
    var onDurationChange: ((String) -> Void)?
    var onVolumeChange: ((Int) -> Void)?
    var onMuteChange: ((Bool) -> Void)?
    var onEndOfFile: (() -> Void)?
    
    init() {
        // 生成随机socket路径
        socketPath = "/tmp/macast_mpvsocket\(Int.random(in: 0...9999))"
    }
    
    // MARK: - 生命周期管理
    
    func start() -> Bool {
        guard !isRunning else { return true }
        
        queue.sync {
            isRunning = true
            launchMPV()
            connectToSocket()
        }
        
        return true
    }
    
    func stop() {
        guard isRunning else { return }
        
        queue.sync {
            isRunning = false
            sendCommand(["quit"])
            socket?.close()
            socket = nil
            process?.terminate()
            process = nil
        }
    }
    
    private func launchMPV() {
        // 获取MPV路径
        let mpvPath = Settings.mpvPath.isEmpty ? "mpv" : Settings.mpvPath
        
        // 构建MPV启动参数
        var arguments: [String] = [
            "--input-ipc-server=\(socketPath)",
            "--idle=yes",
            "--no-terminal",
            "--script-opts=osc-timetotal=yes,osc-layout=bottombar,osc-title=${title},osc-showwindowed=yes,osc-seekbarstyle=bar,osc-visibility=auto"
        ]
        
        // 添加硬件解码参数
        if Settings.hardwareDecode {
            arguments.append("--hwdec=yes")
        }
        
        // 添加播放器位置参数
        switch Settings.playerPosition {
        case .leftTop:
            arguments.append("--geometry=10%:10%")
        case .rightTop:
            arguments.append("--geometry=90%:10%")
        case .leftBottom:
            arguments.append("--geometry=10%:90%")
        case .rightBottom:
            arguments.append("--geometry=90%:90%")
        case .center:
            arguments.append("--geometry=50%:50%")
        }
        
        // 添加播放器大小参数
        switch Settings.playerSize {
        case .small:
            arguments.append("--autofit=50%")
        case .normal:
            arguments.append("--autofit=75%")
        case .large:
            arguments.append("--autofit=90%")
        case .auto:
            arguments.append("--autofit-larger=90%")
        case .fullscreen:
            arguments.append("--fullscreen")
        }
        
        // 添加macOS特有的参数
        if #available(macOS 10.15, *) {
            arguments.append("--macos-app-activation-policy=accessory")
        }
        
        // 创建并启动MPV进程
        process = Process()
        process?.executableURL = URL(fileURLWithPath: mpvPath)
        process?.arguments = arguments
        process?.standardOutput = FileHandle.nullDevice
        process?.standardError = FileHandle.nullDevice
        
        do {
            try process?.run()
            Logging.info("MPV started with arguments: \(arguments.joined(separator: " "))")
        } catch {
            Logging.error("Failed to start MPV: \(error)")
            process = nil
            isRunning = false
        }
    }
    
    // MARK: - IPC通信
    
    private func connectToSocket() {
        // 等待MPV创建socket文件
        var attempts = 0
        let maxAttempts = 10
        
        while attempts < maxAttempts && isRunning {
            if FileManager.default.fileExists(atPath: socketPath) {
                break
            }
            
            Thread.sleep(forTimeInterval: 0.1)
            attempts += 1
        }
        
        if !isRunning || attempts >= maxAttempts {
            Logging.error("Failed to connect to MPV socket after \(maxAttempts) attempts")
            return
        }
        
        // 连接到MPV的IPC socket
        socket = Socket(path: socketPath)
        do {
            try socket?.connect()
            Logging.info("Connected to MPV socket at \(socketPath)")
            
            // 开始监听MPV事件
            listenForEvents()
            
            // 设置观察属性
            setObserveProperties()
            
        } catch {
            Logging.error("Failed to connect to MPV socket: \(error)")
            socket?.close()
            socket = nil
        }
    }
    
    private func listenForEvents() {
        queue.async {
            guard let socket = self.socket else { return }
            
            while self.isRunning {
                do {
                    let data = try socket.read()
                    if data.isEmpty {
                        continue
                    }
                    
                    // 处理接收到的数据
                    self.processMPVResponse(data)
                    
                } catch {
                    Logging.error("Error reading from MPV socket: \(error)")
                    break
                }
            }
            
            // 连接断开
            socket.close()
            self.socket = nil
            
            // 尝试重新连接
            if self.isRunning {
                Thread.sleep(forTimeInterval: 1)
                self.connectToSocket()
            }
        }
    }
    
    private func processMPVResponse(_ data: Data) {
        guard let responseString = String(data: data, encoding: .utf8) else {
            Logging.error("Failed to decode MPV response")
            return
        }
        
        // MPV可能一次发送多个JSON对象，按行分割
        let lines = responseString.split(separator: "\n", omittingEmptySubsequences: true)
        
        for line in lines {
            processMPVMessage(String(line))
        }
    }
    
    private func processMPVMessage(_ message: String) {
        guard let data = message.data(using: .utf8) else { return }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            if let event = json?["event"] as? String {
                // 处理事件
                handleMPVEvent(event, data: json)
            } else if let id = json?["id"] as? Int {
                // 处理命令响应
                handleMPVCommandResponse(id, data: json)
            }
            
        } catch {
            Logging.error("Failed to parse MPV JSON response: \(error)")
        }
    }
    
    private func handleMPVEvent(_ event: String, data: [String: Any]?) {
        Logging.debug("MPV event: \(event)")
        
        switch event {
        case "end-file":
            // 播放结束
            onEndOfFile?()
            onPlayStateChange?(false)
            
        case "start-file":
            // 开始播放新文件
            onPlayStateChange?(true)
            
        case "playback-restart":
            // 播放状态改变
            let isPaused = data?["pause"] as? Bool ?? false
            onPlayStateChange?(!isPaused)
            
        case "seek":
            // 跳过操作
            break
            
        default:
            Logging.debug("Unhandled MPV event: \(event)")
        }
    }
    
    private func handleMPVCommandResponse(_ id: Int, data: [String: Any]?) {
        // 处理命令响应，更新状态
        guard let data = data else { return }
        
        // 根据id匹配对应的命令和处理函数
        // 这里需要维护一个命令id到处理函数的映射
    }
    
    // MARK: - 命令发送
    
    private func sendCommand(_ command: [String]) -> Int? {
        commandLock.lock()
        defer { commandLock.unlock() }
        
        guard isRunning, let socket = socket else { return nil }
        
        // 生成命令ID
        let commandId = Int(Date().timeIntervalSince1970 * 1000)
        
        // 构建JSON命令
        let commandDict: [String: Any] = [
            "command": command,
            "request_id": commandId
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: commandDict)
            let jsonString = String(data: jsonData, encoding: .utf8)! + "\n"
            
            try socket.write(jsonString)
            Logging.debug("Sent MPV command: \(command)")
            
            return commandId
        } catch {
            Logging.error("Failed to send MPV command: \(error)")
            return nil
        }
    }
    
    private func setObserveProperties() {
        // 观察播放位置
        sendCommand(["observe_property", 1, "time-pos"])
        
        // 观察总时长
        sendCommand(["observe_property", 2, "duration"])
        
        // 观察音量
        sendCommand(["observe_property", 3, "volume"])
        
        // 观察静音状态
        sendCommand(["observe_property", 4, "mute"])
        
        // 观察播放状态
        sendCommand(["observe_property", 5, "pause"])
        
        // 观察播放速度
        sendCommand(["observe_property", 6, "speed"])
        
        // 观察轨道列表
        sendCommand(["observe_property", 7, "track-list"])
    }
    
    // MARK: - 播放控制
    
    func setMediaURL(_ url: String, title: String = "") {
        // 停止当前播放
        sendCommand(["stop"])
        
        // 设置标题
        sendCommand(["set_property", "title", title])
        
        // 加载新URL
        sendCommand(["loadfile", url, "replace"])
    }
    
    func setMediaTitle(_ title: String) {
        sendCommand(["set_property", "title", title])
    }
    
    func setMediaPause() {
        sendCommand(["set_property", "pause", true])
    }
    
    func setMediaResume() {
        sendCommand(["set_property", "pause", false])
    }
    
    func setMediaStop() {
        sendCommand(["stop"])
    }
    
    func setMediaPosition(_ position: String) {
        sendCommand(["seek", position, "absolute"])
    }
    
    func setMediaVolume(_ volume: Int) {
        sendCommand(["set_property", "volume", volume])
    }
    
    func setMediaMute(_ mute: Bool) {
        sendCommand(["set_property", "mute", mute])
    }
    
    func setMediaSubtitleFile(_ url: String, title: String = "") {
        sendCommand(["sub-add", url, "select", title])
    }
    
    func setMediaSubtitleShow(_ show: Bool) {
        sendCommand(["set_property", "sub-visibility", show])
    }
    
    func setMediaSpeed(_ speed: Float) {
        sendCommand(["set_property", "speed", speed])
    }
    
    func showText(_ text: String, duration: Int = 1000) {
        sendCommand(["show-text", text, duration])
    }
}

// Socket封装类
class Socket {
    private let path: String
    private var fileDescriptor: Int32 = -1
    
    init(path: String) {
        self.path = path
    }
    
    func connect() throws {
        fileDescriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fileDescriptor != -1 else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
        }
        
        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        strlcpy(&address.sun_path.0, path, MemoryLayout.size(ofValue: address.sun_path))
        
        let addressPtr = UnsafePointer<sockaddr>(OpaquePointer(&address))
        let addressLength = socklen_t(MemoryLayout.size(ofValue: address))
        
        if connect(fileDescriptor, addressPtr, addressLength) == -1 {
            let error = NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
            close(fileDescriptor)
            fileDescriptor = -1
            throw error
        }
    }
    
    func write(_ data: String) throws {
        guard fileDescriptor != -1 else {
            throw NSError(domain: "SocketError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Socket not connected"])
        }
        
        let bytesWritten = write(fileDescriptor, data, data.utf8.count)
        guard bytesWritten != -1 else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
        }
    }
    
    func read() throws -> Data {
        guard fileDescriptor != -1 else {
            throw NSError(domain: "SocketError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Socket not connected"])
        }
        
        var buffer = [UInt8](repeating: 0, count: 4096)
        let bytesRead = read(fileDescriptor, &buffer, buffer.count)
        
        guard bytesRead != -1 else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
        }
        
        if bytesRead == 0 {
            throw NSError(domain: "SocketError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Connection closed"])
        }
        
        return Data(buffer[0..<bytesRead])
    }
    
    func close() {
        if fileDescriptor != -1 {
            Darwin.close(fileDescriptor)
            fileDescriptor = -1
        }
    }
    
    deinit {
        close()
    }
}
```

### 4.3 错误处理和恢复机制

```swift
class MPVErrorHandler {
    static func handleMPVError(_ error: Error) {
        Logging.error("MPV error: \(error)")
        
        // 根据错误类型采取不同的恢复策略
        let nsError = error as NSError
        
        switch nsError.domain {
        case NSPOSIXErrorDomain:
            // 处理POSIX错误
            handlePOSIXError(nsError.code)
            
        case "SocketError":
            // 处理Socket错误
            handleSocketError(nsError.code)
            
        default:
            // 处理其他错误
            showErrorNotification(error.localizedDescription)
        }
    }
    
    private static func handlePOSIXError(_ code: Int) {
        switch code {
        case ECONNREFUSED, ECONNRESET, EPIPE:
            // 连接错误，尝试重新连接
            Logging.info("MPV connection error, attempting to reconnect...")
            
        case ENOENT:
            // MPV二进制文件不存在
            showErrorNotification("MPV executable not found. Please check your MPV path in preferences.")
            
        default:
            showErrorNotification("MPV error: \(String(cString: strerror(Int32(code))))")
        }
    }
    
    private static func handleSocketError(_ code: Int) {
        switch code {
        case -1: // Socket not connected
            Logging.info("MPV socket not connected, attempting to reconnect...")
            
        case -2: // Connection closed
            Logging.info("MPV connection closed, attempting to reconnect...")
            
        default:
            showErrorNotification("Socket error occurred")
        }
    }
    
    private static func showErrorNotification(_ message: String) {
        let notification = NSUserNotification()
        notification.title = "Macast"
        notification.subtitle = "MPV Error"
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
}
```

## 5. macOS用户体验优化方案

### 5.1 菜单栏应用优化

```swift
class StatusMenuController {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private var preferencesWindowController: PreferencesWindowController?
    private var aboutWindowController: AboutWindowController?
    
    func setup() {
        // 设置菜单图标
        if let button = statusItem.button {
            // 使用模板图标以支持暗色模式
            button.image = NSImage(named: "MenuBarIcon")
            button.image?.isTemplate = true
            button.toolTip = "Macast - DLNA Media Renderer"
        }
        
        // 构建菜单项
        buildMenu()
        
        // 设置菜单
        statusItem.menu = menu
        
        // 支持拖拽文件到菜单图标
        setupDragAndDrop()
    }
    
    private func buildMenu() {
        // 添加播放器控制菜单项
        let playerMenu = NSMenu()
        addPlayerControlItems(to: playerMenu)
        
        let playerMenuItem = NSMenuItem(title: "播放器控制", action: nil, keyEquivalent: "")
        playerMenuItem.submenu = playerMenu
        menu.addItem(playerMenuItem)
        
        // 添加分隔线
        menu.addItem(NSMenuItem.separator())
        
        // 添加偏好设置菜单项
        let preferencesItem = NSMenuItem(
            title: "偏好设置...",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        preferencesItem.target = self
        menu.addItem(preferencesItem)
        
        // 添加关于菜单项
        let aboutItem = NSMenuItem(
            title: "关于Macast",
            action: #selector(openAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        // 添加分隔线
        menu.addItem(NSMenuItem.separator())
        
        // 添加退出菜单项
        let quitItem = NSMenuItem(
            title: "退出",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    private func addPlayerControlItems(to menu: NSMenu) {
        // 播放/暂停
        let playPauseItem = NSMenuItem(
            title: "播放/暂停",
            action: #selector(togglePlayPause),
            keyEquivalent: " "
        )
        playPauseItem.target = self
        menu.addItem(playPauseItem)
        
        // 停止
        let stopItem = NSMenuItem(
            title: "停止",
            action: #selector(stopPlayback),
            keyEquivalent: "s"
        )
        stopItem.target = self
        menu.addItem(stopItem)
        
        // 音量控制
        let volumeMenu = NSMenu()
        addVolumeControlItems(to: volumeMenu)
        
        let volumeMenuItem = NSMenuItem(title: "音量", action: nil, keyEquivalent: "")
        volumeMenuItem.submenu = volumeMenu
        menu.addItem(volumeMenuItem)
    }
    
    private func addVolumeControlItems(to menu: NSMenu) {
        // 音量增加
        let increaseVolumeItem = NSMenuItem(
            title: "增加音量",
            action: #selector(increaseVolume),
            keyEquivalent: "+"
        )
        increaseVolumeItem.target = self
        menu.addItem(increaseVolumeItem)
        
        // 音量减少
        let decreaseVolumeItem = NSMenuItem(
            title: "减少音量",
            action: #selector(decreaseVolume),
            keyEquivalent: "-"
        )
        decreaseVolumeItem.target = self
        menu.addItem(decreaseVolumeItem)
        
        // 静音切换
        let muteItem = NSMenuItem(
            title: "静音",
            action: #selector(toggleMute),
            keyEquivalent: "m"
        )
        muteItem.target = self
        menu.addItem(muteItem)
    }
    
    private func setupDragAndDrop() {
        if let button = statusItem.button {
            button.registerForDraggedTypes([.fileURL])
            button.setDraggingSourceOperationMask([.copy], forLocal: false)
        }
    }
    
    // MARK: - 菜单项动作
    
    @objc private func openPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController()
        }
        preferencesWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func openAbout() {
        if aboutWindowController == nil {
            aboutWindowController = AboutWindowController()
        }
        aboutWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc private func togglePlayPause() {
        // 实现播放/暂停逻辑
    }
    
    @objc private func stopPlayback() {
        // 实现停止逻辑
    }
    
    @objc private func increaseVolume() {
        // 实现音量增加逻辑
    }
    
    @objc private func decreaseVolume() {
        // 实现音量减少逻辑
    }
    
    @objc private func toggleMute() {
        // 实现静音切换逻辑
    }
}
```

### 5.2 暗色模式支持

```swift
// 1. 使用模板图标
imageView.image?.isTemplate = true

// 2. 使用NSColor的动态颜色
label.textColor = NSColor.labelColor
backgroundView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

// 3. 监听暗色模式切换
NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleAppearanceChange),
    name: NSApplication.effectiveAppearanceDidChangeNotification,
    object: nil
)

@objc private func handleAppearanceChange() {
    // 更新UI以适应新的外观模式
    updateUIForCurrentAppearance()
}

private func updateUIForCurrentAppearance() {
    let isDarkMode = NSApp.effectiveAppearance.name == .darkAqua
    // 根据暗色模式状态更新UI元素
}
```

### 5.3 启动项管理

```swift
class LaunchAtLoginManager {
    private static let serviceIdentifier = "com.macast.helper"
    
    static func isEnabled() -> Bool {
        guard let jobs = SMCopyAllJobDictionaries(kSMDomainUserLaunchd)?.takeRetainedValue() as? [[String: Any]] else {
            return false
        }
        
        return jobs.contains { $0["Label"] as? String == serviceIdentifier }
    }
    
    static func setEnabled(_ enabled: Bool) -> Bool {
        let status = SMLoginItemSetEnabled(serviceIdentifier as CFString, enabled)
        return status
    }
}
```

### 5.4 用户通知系统

```swift
class NotificationManager {
    static func showPlaybackStartedNotification(title: String) {
        guard Settings.showNotifications else { return }
        
        let notification = NSUserNotification()
        notification.title = "Macast"
        notification.subtitle = "播放开始"
        notification.informativeText = "正在播放：\(title)"
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    static func showPlaybackStoppedNotification() {
        guard Settings.showNotifications else { return }
        
        let notification = NSUserNotification()
        notification.title = "Macast"
        notification.subtitle = "播放停止"
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    static func showConnectionErrorNotification() {
        guard Settings.showNotifications else { return }
        
        let notification = NSUserNotification()
        notification.title = "Macast"
        notification.subtitle = "连接错误"
        notification.informativeText = "无法连接到媒体服务器"
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    static func showMPVErrorNotification(message: String) {
        guard Settings.showNotifications else { return }
        
        let notification = NSUserNotification()
        notification.title = "Macast"
        notification.subtitle = "播放器错误"
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
}
```

## 6. Swift插件系统设计

### 6.1 核心协议定义

```swift
// 插件基础协议
protocol MacastPlugin {
    var name: String { get }
    var title: String { get }
    var version: String { get }
    var author: String { get }
 String { get }
    var platform: [String] { get }
    var type: PluginType { get }
}

enum PluginType {
    case renderer
    case protocol
    case unknown
}

// 渲染器插件协议
extension MacastPlugin where Self: DLNARenderer {
    var type: PluginType { .renderer }
}

// 协议插件协议
extension MacastPlugin where Self: DLNAProtocol {
    var type: PluginType { .protocol }
}

// DLNA渲染器协议
protocol DLNARenderer {
    func start() -> Bool
    func stop()
    func pause()
    func resume()
    func setMediaURL(_ url: String, title: String)
    func setMediaPosition(_ position: String)
    func setMediaVolume(_ volume: Int)
    func setMediaMute(_ mute: Bool)
    func setMediaSubtitleFile(_ url: String, title: String)
    func setMediaSubtitleShow(_ show: Bool)
    func setMediaSpeed(_ speed: Float)
    
    // 回调
    var onPlayStateChange: ((Bool) -> Void)? { get set }
    var onPositionChange: ((String) -> Void)? { get set }
    var onDurationChange: ((String) -> Void)? { get set }
    var onVolumeChange: ((Int) -> Void)? { get set }
    var onMuteChange: ((Bool) -> Void)? { get set }
    var onEndOfFile: (() -> Void)? { get set }
}

// DLNA协议插件协议
protocol DLNAProtocol {
    func start()
    func stop()
    func handleRequest(_ request: HTTPRequest) -> HTTPResponse
}
```

## 7. IINA替代MPV播放器的可行性分析与实现方案

### 7.1 IINA与MPV的关系

IINA是基于MPV开发的macOS专用媒体播放器，它提供了：
- 现代化的macOS用户界面
- 更深入的macOS系统集成（Touch Bar、Force Touch等）
- 更好的媒体库管理
- 基于MPV的核心播放功能

### 7.2 使用IINA的优势

#### 7.2.1 用户体验提升
- 原生macOS界面设计，符合平台规范
- 支持更多macOS特有功能（如画中画、HDR支持）
- 更好的字幕和音频处理

#### 7.2.2 技术优势
- 基于MPV核心，兼容MPV的大多数功能
- 更好的macOS系统资源管理
- 定期更新，维护良好

#### 7.2.3 集成优势
- 可以通过AppleScript或命令行控制
- 支持URL Scheme，可以直接从浏览器或其他应用启动

### 7.3 可行性分析

#### 7.3.1 IINA控制方式

IINA支持多种控制方式：

1. **AppleScript**：通过AppleScript可以控制IINA的几乎所有功能
2. **命令行接口**：支持部分命令行参数
3. **URL Scheme**：支持通过URL启动播放
4. **MPV IPC接口**：由于IINA基于MPV，理论上可以通过MPV的IPC接口控制

#### 7.3.2 与Macast需求匹配度

Macast需要的播放器功能：
- 播放、暂停、停止控制
- 音量调整和静音
- 进度控制（跳转）
- 媒体URL加载
- 字幕控制
- 播放状态监控

IINA通过AppleScript可以实现所有这些功能，因此技术上是可行的。

### 7.4 实现方案

#### 7.4.1 核心实现思路

使用AppleScript与IINA通信，实现Macast需要的所有播放器控制功能。

#### 7.4.2 实现代码

```swift
import Foundation

class IINARenderer: NSObject, DLNARenderer {
    // DLNARenderer协议实现
    var onPlayStateChange: ((Bool) -> Void)?
    var onPositionChange: ((String) -> Void)?
    var onDurationChange: ((String) -> Void)?
    var onVolumeChange: ((Int) -> Void)?
    var onMuteChange: ((Bool) -> Void)?
    var onEndOfFile: (() -> Void)?
    
    private var timer: Timer?
    private var isPlaying: Bool = false
    private var isMuted: Bool = false
    private var volume: Int = 100
    private var currentPosition: TimeInterval = 0
    private var duration: TimeInterval = 0
    
    func start() -> Bool {
        // 启动IINA应用
        let script = "tell application \"IINA\" to activate"
        executeAppleScript(script)
        
        // 启动状态监控
        startMonitoring()
        
        return true
    }
    
    func stop() {
        // 停止播放并关闭IINA
        let script = "tell application \"IINA\"\n    stop\n    quit\nend tell"
        executeAppleScript(script)
        
        // 停止状态监控
        stopMonitoring()
    }
    
    func pause() {
        let script = "tell application \"IINA\" to pause"
        executeAppleScript(script)
        isPlaying = false
        onPlayStateChange?(false)
    }
    
    func resume() {
        let script = "tell application \"IINA\" to play"
        executeAppleScript(script)
        isPlaying = true
        onPlayStateChange?(true)
    }
    
    func setMediaURL(_ url: String, title: String) {
        // 使用URL Scheme播放媒体
        if let mediaURL = URL(string: url),
           let iinaURL = URL(string: "iina://weblink?url=\(mediaURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? \"")") {
            NSWorkspace.shared.open(iinaURL)
        }
        
        // 设置标题
        let titleScript = "tell application \"IINA\" to set name of current playlist item to \"\(title)\""
        executeAppleScript(titleScript)
    }
    
    func setMediaPosition(_ position: String) {
        // 解析时间格式 (HH:MM:SS)
        let components = position.split(separator: ":")
        guard components.count == 3,
              let hours = Double(components[0]),
              let minutes = Double(components[1]),
              let seconds = Double(components[2]) else {
            return
        }
        
        let totalSeconds = hours * 3600 + minutes * 60 + seconds
        
        let script = "tell application \"IINA\" to set current time of current playlist item to \(totalSeconds)"
        executeAppleScript(script)
        currentPosition = totalSeconds
        onPositionChange?(position)
    }
    
    func setMediaVolume(_ volume: Int) {
        let script = "tell application \"IINA\" to set volume of current playlist item to \(volume)"
        executeAppleScript(script)
        self.volume = volume
        onVolumeChange?(volume)
    }
    
    func setMediaMute(_ mute: Bool) {
        let script = "tell application \"IINA\" to set muted of current playlist item to \(mute)"
        executeAppleScript(script)
        self.isMuted = mute
        onMuteChange?(mute)
    }
    
    func setMediaSubtitleFile(_ url: String, title: String) {
        // IINA不支持通过AppleScript直接添加字幕文件
        // 可以考虑通过命令行参数或URL Scheme实现
        let script = "tell application \"IINA\" to set subtitle track of current playlist item to 1"
        executeAppleScript(script)
    }
    
    func setMediaSubtitleShow(_ show: Bool) {
        let script = "tell application \"IINA\" to set visible of subtitle track of current playlist item to \(show)"
        executeAppleScript(script)
    }
    
    func setMediaSpeed(_ speed: Float) {
        let script = "tell application \"IINA\" to set speed of current playlist item to \(speed)"
        executeAppleScript(script)
    }
    
    // MARK: - 辅助方法
    
    private func executeAppleScript(_ script: String) {
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        
        appleScript?.executeAndReturnError(&error)
        
        if let error = error {
            Logging.error("AppleScript execution error: \(error)")
        }
    }
    
    private func startMonitoring() {
        // 启动定时检查IINA状态
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(checkIINAState), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func checkIINAState() {
        // 检查播放状态
        let playStateScript = "tell application \"IINA\" to get playing"
        if let result = executeAppleScriptAndReturnResult(playStateScript) as? Bool {
            if result != isPlaying {
                isPlaying = result
                onPlayStateChange?(result)
            }
        }
        
        // 检查音量
        let volumeScript = "tell application \"IINA\" to get volume of current playlist item"
        if let result = executeAppleScriptAndReturnResult(volumeScript) as? Int {
            if result != volume {
                volume = result
                onVolumeChange?(result)
            }
        }
        
        // 检查静音状态
        let muteScript = "tell application \"IINA\" to get muted of current playlist item"
        if let result = executeAppleScriptAndReturnResult(muteScript) as? Bool {
            if result != isMuted {
                isMuted = result
                onMuteChange?(result)
            }
        }
        
        // 检查当前播放位置
        let positionScript = "tell application \"IINA\" to get current time of current playlist item"
        if let result = executeAppleScriptAndReturnResult(positionScript) as? TimeInterval {
            if abs(result - currentPosition) > 1.0 { // 避免频繁更新
                currentPosition = result
                let formattedTime = formatTime(seconds: result)
                onPositionChange?(formattedTime)
            }
        }
        
        // 检查总时长
        let durationScript = "tell application \"IINA\" to get duration of current playlist item"
        if let result = executeAppleScriptAndReturnResult(durationScript) as? TimeInterval {
            if result != duration {
                duration = result
                let formattedTime = formatTime(seconds: result)
                onDurationChange?(formattedTime)
            }
        }
        
        // 检查是否播放结束
        let endScript = "tell application \"IINA\" to get end reached"
        if let result = executeAppleScriptAndReturnResult(endScript) as? Bool {
            if result {
                onEndOfFile?()
            }
        }
    }
    
    private func executeAppleScriptAndReturnResult(_ script: String) -> Any? {
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        
        guard let result = appleScript?.executeAndReturnError(&error) else {
            if let error = error {
                Logging.error("AppleScript execution error: \(error)")
            }
            return nil
        }
        
        return result.stringValue != nil ? result.stringValue : result.booleanValue
    }
    
    private func formatTime(seconds: TimeInterval) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}

// MARK: - IINA渲染器设置

class IINARendererSetting {
    var iinaPath: String {
        get {
            // 默认IINA路径
            return "/Applications/IINA.app"
        }
    }
    
    func isIINAAvailable() -> Bool {
        return FileManager.default.fileExists(atPath: iinaPath)
    }
    
    func getIINAExecutablePath() -> String {
        return "\(iinaPath)/Contents/MacOS/IINA"
    }
}
```

#### 7.4.3 实现注意事项

1. **IINA安装检测**：在使用前检查IINA是否已安装
2. **AppleScript权限**：macOS 10.14+需要获得AppleScript控制权限
3. **状态同步**：需要定期同步IINA的状态到Macast
4. **错误处理**：处理IINA未运行或命令执行失败的情况

### 7.5 与MPV方案的对比

| 特性 | MPV方案 | IINA方案 |
|------|---------|----------|
| 跨平台支持 | 是 | 否（仅macOS） |
| 启动速度 | 快 | 稍慢（需要加载界面） |
| 资源占用 | 低 | 稍高（需要运行完整应用） |
| 控制方式 | IPC Socket | AppleScript/命令行 |
| macOS集成 | 基本 | 优秀 |
| 用户界面 | 无/极简 | 现代化macOS界面 |
| 功能完整性 | 高 | 高（基于MPV） |
| 自定义性 | 高 | 中等 |

### 7.6 实现策略

#### 7.6.1 双播放器支持

建议在Macast Swift重写中实现双播放器支持：

1. **默认使用MPV**：保持跨平台兼容性和性能
2. **可选切换到IINA**：为macOS用户提供更好的体验

#### 7.6.2 实现步骤

1. 实现IINA渲染器类（如上述代码）
2. 在插件系统中添加IINA渲染器
3. 在偏好设置中添加播放器选择选项
4. 实现播放器切换逻辑
5. 添加IINA安装检测和引导

### 7.7 代码集成示例

#### 7.7.1 播放器选择界面

```swift
class PlayerSettingsViewController: NSViewController {
    @IBOutlet private var playerTypePopup: NSPopUpButton!
    @IBOutlet private var mpvPathField: NSTextField!
    @IBOutlet private var iinaInfoLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 加载播放器类型选项
        playerTypePopup.removeAllItems()
        playerTypePopup.addItem(withTitle: "MPV")
        
        let iinaSetting = IINARendererSetting()
        if iinaSetting.isIINAAvailable() {
            playerTypePopup.addItem(withTitle: "IINA")
            iinaInfoLabel.stringValue = "IINA已安装，可以使用"
        } else {
            iinaInfoLabel.stringValue = "IINA未安装，点击下方链接安装"
        }
        
        // 选择当前播放器
        let currentPlayer = Settings.selectedPlayerType
        playerTypePopup.selectItem(withTitle: currentPlayer)
        
        // 显示/隐藏相关设置
        updatePlayerSettingsVisibility()
    }
    
    @IBAction private func playerTypeChanged(_ sender: NSPopUpButton) {
        updatePlayerSettingsVisibility()
        
        // 保存选择
        if let selectedPlayer = sender.selectedItem?.title {
            Settings.selectedPlayerType = selectedPlayer
        }
    }
    
    private func updatePlayerSettingsVisibility() {
        if let selectedPlayer = playerTypePopup.selectedItem?.title {
            mpvPathField.isHidden = selectedPlayer != "MPV"
            // 其他播放器的设置字段
        }
    }
    
    @IBAction private func installIINA(_ sender: NSButton) {
        // 打开IINA下载页面
        if let url = URL(string: "https://iina.io/") {
            NSWorkspace.shared.open(url)
        }
    }
}
```

#### 7.7.2 播放器切换逻辑

```swift
class PluginManager {
    func createRendererInstance() -> DLNARenderer {
        let playerType = Settings.selectedPlayerType
        
        switch playerType {
        case "IINA":
            return IINARenderer()
        case "MPV":
        default:
            return MPVController()
        }
    }
}
```

### 7.8 总结

在Macast Swift重写中使用IINA替代MPV是完全可行的，并且可以为macOS用户提供更好的体验。IINA基于MPV核心，兼容大部分MPV功能，同时提供了更好的macOS集成和用户界面。

推荐实现双播放器支持，默认使用MPV保持兼容性，同时为macOS用户提供切换到IINA的选项。这样可以兼顾跨平台需求和macOS用户体验。

需要注意的是，使用IINA需要处理AppleScript权限问题，并且IINA的启动速度和资源占用略高于MPV。但对于macOS用户来说，这些权衡是值得的，因为可以获得更好的用户体验和系统集成。

## 8. 多协议支持分析

### 8.1 现有协议支持情况

Macast目前主要支持DLNA协议，用于实现媒体投屏功能。DLNA是一种开放的网络协议标准，允许不同厂商的设备在同一网络中共享媒体内容。

### 8.2 潜在的协议扩展需求

随着智能设备的多样化，用户可能需要Macast支持更多的投屏协议，包括：
1. AirPlay（Apple设备）
2. Chromecast（Google设备）
3. Miracast（Windows设备）
4. 华为Cast+（华为设备）

### 8.3 各协议技术分析

#### 8.3.1 AirPlay

AirPlay是Apple开发的专有协议，用于在Apple设备之间传输媒体内容。

**技术特点：**
- 基于UDP和TCP协议
- 支持音频、视频和屏幕镜像
- 支持加密传输
- 支持多房间音频

**实现难度：**
- 中等至高，因为是专有协议，没有完整的官方文档
- 需要处理DRM内容（FairPlay）
- 需要实现AirPlay 1和AirPlay 2的兼容性

**关键技术点：**
- 实现AirPlay服务器（apserver）
- 支持RTSP/RTP媒体流
- 处理AirPlay镜像协议（AirTunes）

#### 8.3.2 Chromecast

Chromecast是Google开发的投屏设备，使用DIAL和Cast协议。

**技术特点：**
- 基于HTTP和WebSocket协议
- 使用DIAL进行设备发现和应用启动
- 使用Cast协议进行媒体控制
- 支持Web应用和原生应用

**实现难度：**
- 中等，有较完整的官方文档
- 需要实现DIAL服务器
- 需要实现Cast协议接收器

**关键技术点：**
- 实现DIAL服务器（Discovery and Launch）
- 实现Cast协议接收器（Cast Receiver SDK）
- 支持HLS和DASH流媒体格式

#### 8.3.3 Miracast

Miracast是Wi-Fi Alliance定义的无线显示标准，基于Wi-Fi Direct技术。

**技术特点：**
- 基于Wi-Fi Direct协议
- 支持屏幕镜像和媒体流传输
- 支持HDCP加密
- 与Wi-Fi Display兼容

**实现难度：**
- 高，需要底层系统支持
- 需要实现Wi-Fi Direct连接管理
- 需要处理实时视频编码和解码

**关键技术点：**
- 实现Wi-Fi Direct连接
- 支持H.264视频编码
- 实现RTSP/RTP媒体流

#### 8.3.4 华为Cast+

华为Cast+是华为基于Miracast扩展的投屏协议，增加了更多功能和优化。

**技术特点：**
- 基于Miracast协议
- 支持4K视频传输
- 支持多声道音频
- 支持触控反向控制

**实现难度：**
- 高，因为是专有扩展
- 需要先实现Miracast
- 需要处理华为设备的兼容性

**关键技术点：**
- 实现Miracast基础功能
- 增加华为Cast+扩展功能
- 优化传输性能

### 8.4 协议对比分析

| 协议 | 设备兼容性 | 实现难度 | 性能 | 功能完整性 | 开放程度 |
|------|------------|----------|------|------------|----------|
| DLNA | 广泛 | 低 | 中等 | 基本 | 开放标准 |
| AirPlay | Apple设备 | 高 | 高 | 完整 | 专有协议 |
| Chromecast | Google设备 | 中等 | 高 | 完整 | 半开放 |
| Miracast | Windows/Android设备 | 高 | 中等 | 基本 | 开放标准 |
| 华为Cast+ | 华为设备 | 高 | 高 | 完整 | 专有协议 |

### 8.5 多协议支持的实现策略

#### 8.5.1 核心设计原则

1. **模块化设计**：每个协议实现为独立模块，通过统一接口与核心系统交互
2. **低耦合**：协议模块之间和协议模块与核心系统之间保持低耦合
3. **可扩展性**：便于添加新的协议支持
4. **性能优化**：确保多协议同时运行时的性能

#### 8.5.2 架构设计

```
┌─────────────────────────────────────────────────┐
│                   Macast Core                   │
├───────────┬───────────┬───────────┬───────────┤
│  DLNA     │  AirPlay  │ Chromecast│ Miracast  │
│  模块     │  模块     │  模块     │  模块     │
└───────────┴───────────┴───────────┴───────────┘
```

**核心组件：**

1. **协议管理器**：负责管理所有协议模块的生命周期和调度
2. **统一接口层**：定义统一的媒体控制接口，屏蔽不同协议的差异
3. **设备发现服务**：集成各协议的设备发现功能
4. **媒体渲染服务**：统一处理媒体流的接收和渲染

#### 8.5.3 实现步骤

1. **第一步：完善DLNA协议**
   - 优化现有DLNA实现
   - 支持更多DLNA特性
   - 提高稳定性和性能

2. **第二步：添加AirPlay支持**
   - 实现AirPlay服务器
   - 支持音频和视频传输
   - 支持屏幕镜像

3. **第三步：添加Chromecast支持**
   - 实现DIAL服务器
   - 实现Cast协议接收器
   - 支持Web应用和原生应用

4. **第四步：添加Miracast支持**（可选）
   - 实现Wi-Fi Direct连接
   - 支持屏幕镜像
   - 优化性能

5. **第五步：添加华为Cast+支持**（可选）
   - 基于Miracast扩展
   - 支持华为设备的特殊功能

### 8.6 关键技术实现

#### 8.6.1 统一媒体控制接口

```swift
protocol MediaRenderer {
    func play()
    func pause()
    func stop()
    func setVolume(_ volume: Int)
    func setPosition(_ position: TimeInterval)
    func loadMedia(_ url: URL, title: String?, subtitleURL: URL?)
}
```

#### 8.6.2 协议模块基类

```swift
class ProtocolModule {
    var name: String
    var isRunning: Bool = false
    
    init(name: String) {
        self.name = name
    }
    
    func start() throws {
        isRunning = true
    }
    
    func stop() {
        isRunning = false
    }
    
    func handleRequest(_ request: Request) -> Response? {
        return nil
    }
}
```

#### 8.6.3 协议管理器

```swift
class ProtocolManager {
    private var modules: [ProtocolModule] = []
    
    func registerModule(_ module: ProtocolModule) {
        modules.append(module)
    }
    
    func startAllModules() throws {
        for module in modules {
            try module.start()
        }
    }
    
    func stopAllModules() {
        for module in modules {
            module.stop()
        }
    }
    
    func handleRequest(_ request: Request) -> Response? {
        for module in modules {
            if let response = module.handleRequest(request) {
                return response
            }
        }
        return nil
    }
}
```

### 8.7 性能优化与资源管理

#### 8.7.1 资源隔离

- 为每个协议模块分配独立的线程或队列
- 使用异步I/O处理网络请求
- 限制每个模块的内存使用

#### 8.7.2 性能监控

- 监控每个协议模块的CPU和内存使用
- 监控网络延迟和带宽使用
- 动态调整资源分配

#### 8.7.3 能量管理

- 在低电量模式下自动关闭非必要的协议
- 优化网络请求频率
- 使用高效的编码格式

### 8.8 测试与兼容性验证

#### 8.8.1 测试策略

- 单元测试：测试每个协议模块的功能
- 集成测试：测试多协议同时运行的兼容性
- 性能测试：测试在高负载下的性能
- 兼容性测试：测试与不同设备的兼容性

#### 8.8.2 兼容性验证

- 测试与不同品牌和型号的DLNA设备
- 测试与不同版本的iOS设备（AirPlay）
- 测试与不同版本的Chromecast设备
- 测试与Windows和Android设备（Miracast）
- 测试与华为设备（华为Cast+）

### 8.9 实现优先级建议

根据实现难度、用户需求和技术可行性，建议的实现优先级为：

1. **DLNA**：继续完善现有实现，确保稳定性和性能
2. **AirPlay**：满足Apple设备用户的需求
3. **Chromecast**：满足Google设备用户的需求
4. **Miracast/华为Cast+**：根据用户反馈决定是否实现

### 8.10 总结

在Macast中实现多协议支持是可行的，但需要分阶段进行。通过模块化设计和统一接口，可以在不影响现有功能的前提下添加新的协议支持。

优先实现DLNA的完善和AirPlay支持，可以满足大部分用户的需求。Chromecast支持可以作为下一步，而Miracast和华为Cast+可以根据用户反馈和技术成熟度决定是否实现。

实现多协议支持需要考虑性能优化和资源管理，确保在同时运行多个协议时不会影响系统性能。同时，需要进行充分的测试和兼容性验证，确保与不同设备的正常工作。
