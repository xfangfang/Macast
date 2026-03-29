import Foundation
import Network

// MARK: - BrowserExtensionManager

/// 浏览器扩展管理器，负责处理浏览器扩展与Macast的通信
class BrowserExtensionManager {
    
    // MARK: - Properties
    
    /// 单例实例
    static let shared = BrowserExtensionManager()
    
    /// 本地消息主机配置
    private let nativeMessagingConfig: NativeMessagingConfig
    
    /// 已注册的扩展消息处理器
    private var messageHandlers: [BrowserExtensionMessageHandler] = []
    
    /// 已连接的扩展
    private var connectedExtensions: [BrowserExtensionConnection] = []
    
    /// 消息队列
    private var messageQueue: [BrowserExtensionMessage] = []
    
    // MARK: - Initialization
    
    private init() {
        // 初始化本地消息主机配置
        nativeMessagingConfig = NativeMessagingConfig(
            hostName: "com.macast.browser_extension",
            description: "Macast浏览器扩展通信主机",
            path: Bundle.main.bundleURL.path,
            type: "stdio",
            allowedOrigins: [
                "chrome-extension://*",
                "moz-extension://*",
                "safari-web-extension://*"
            ]
        )
        
        // 设置本地消息主机
        setupNativeMessagingHost()
    }
    
    // MARK: - Public Methods
    
    /// 启动浏览器扩展管理器
    func start() throws {
        // 启动本地消息处理器
        try startNativeMessagingHandler()
        
        print("浏览器扩展管理器已启动")
    }
    
    /// 停止浏览器扩展管理器
    func stop() {
        // 停止本地消息处理器
        stopNativeMessagingHandler()
        
        // 关闭所有连接
        closeAllConnections()
        
        print("浏览器扩展管理器已停止")
    }
    
    /// 注册消息处理器
    /// - Parameter handler: 消息处理器
    func registerMessageHandler(_ handler: BrowserExtensionMessageHandler) {
        if !messageHandlers.contains(where: { $0 === handler }) {
            messageHandlers.append(handler)
            print("已注册浏览器扩展消息处理器: \(type(of: handler))")
        }
    }
    
    /// 取消注册消息处理器
    /// - Parameter handler: 消息处理器
    func unregisterMessageHandler(_ handler: BrowserExtensionMessageHandler) {
        if let index = messageHandlers.firstIndex(where: { $0 === handler }) {
            messageHandlers.remove(at: index)
            print("已取消注册浏览器扩展消息处理器: \(type(of: handler))")
        }
    }
    
    /// 发送消息到所有连接的扩展
    /// - Parameter message: 要发送的消息
    func sendMessageToAllExtensions(_ message: BrowserExtensionMessage) {
        for connection in connectedExtensions {
            sendMessage(message, to: connection)
        }
    }
    
    /// 发送消息到指定扩展
    /// - Parameters:
    ///   - message: 要发送的消息
    ///   - connection: 扩展连接
    func sendMessage(_ message: BrowserExtensionMessage, to connection: BrowserExtensionConnection) {
        do {
            // 序列化消息
            let messageData = try JSONEncoder().encode(message)
            
            // 发送消息
            connection.sendMessage(messageData)
        } catch {
            print("发送消息失败: \(error.localizedDescription)")
        }
    }
    
    /// 获取已连接的扩展列表
    func getConnectedExtensions() -> [BrowserExtensionConnection] {
        return connectedExtensions
    }
    
    // MARK: - Private Methods
    
    /// 设置本地消息主机
    private func setupNativeMessagingHost() {
        // 为不同浏览器设置本地消息主机配置文件
        setupChromeNativeMessagingHost()
        setupFirefoxNativeMessagingHost()
        setupSafariNativeMessagingHost()
    }
    
    /// 设置Chrome本地消息主机
    private func setupChromeNativeMessagingHost() {
        // 获取Chrome本地消息主机目录
        let chromeHostDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Google/Chrome/NativeMessagingHosts")
        
        // 创建配置文件路径
        let configFileURL = chromeHostDir.appendingPathComponent("\(nativeMessagingConfig.hostName).json")
        
        // 写入配置文件
        writeNativeMessagingConfig(to: configFileURL)
    }
    
    /// 设置Firefox本地消息主机
    private func setupFirefoxNativeMessagingHost() {
        // 获取Firefox本地消息主机目录
        let firefoxHostDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Firefox/NativeMessagingHosts")
        
        // 创建配置文件路径
        let configFileURL = firefoxHostDir.appendingPathComponent("\(nativeMessagingConfig.hostName).json")
        
        // 写入配置文件
        writeNativeMessagingConfig(to: configFileURL)
    }
    
    /// 设置Safari本地消息主机
    private func setupSafariNativeMessagingHost() {
        // Safari使用不同的机制，这里简化处理
        print("Safari扩展支持已配置")
    }
    
    /// 写入本地消息主机配置文件
    private func writeNativeMessagingConfig(to url: URL) {
        do {
            // 创建目录（如果不存在）
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            
            // 序列化配置
            let configData = try JSONEncoder().encode(nativeMessagingConfig)
            
            // 写入文件
            try configData.write(to: url, options: .atomic)
            
            print("已写入本地消息主机配置: \(url.path)")
        } catch {
            print("写入本地消息主机配置失败: \(error.localizedDescription)")
        }
    }
    
    /// 启动本地消息处理器
    private func startNativeMessagingHandler() throws {
        // 设置标准输入/输出处理
        setupSTDIOHandler()
    }
    
    /// 停止本地消息处理器
    private func stopNativeMessagingHandler() {
        // 清理标准输入/输出处理
        cleanupSTDIOHandler()
    }
    
    /// 设置标准输入/输出处理
    private func setupSTDIOHandler() {
        // 获取标准输入/输出流
        let stdin = FileHandle.standardInput
        let stdout = FileHandle.standardOutput
        
        // 设置输入流处理
        NotificationCenter.default.addObserver(forName: FileHandle.readCompletionNotification, object: stdin, queue: nil) { [weak self] notification in
            if let data = notification.userInfo?[NSFileHandleNotificationDataItem] as? Data {
                self?.handleNativeMessage(data)
            }
            
            // 继续读取输入
            stdin.readInBackgroundAndNotify()
        }
        
        // 开始读取输入
        stdin.readInBackgroundAndNotify()
        
        print("标准输入/输出处理器已设置")
    }
    
    /// 清理标准输入/输出处理
    private func cleanupSTDIOHandler() {
        // 移除通知观察者
        NotificationCenter.default.removeObserver(self, name: FileHandle.readCompletionNotification, object: FileHandle.standardInput)
        
        print("标准输入/输出处理器已清理")
    }
    
    /// 处理本地消息
    private func handleNativeMessage(_ data: Data) {
        do {
            // 解析消息
            let message = try JSONDecoder().decode(BrowserExtensionMessage.self, from: data)
            
            // 处理消息
            processMessage(message)
        } catch {
            print("解析消息失败: \(error.localizedDescription)")
        }
    }
    
    /// 处理消息
    private func processMessage(_ message: BrowserExtensionMessage) {
        // 将消息分发给所有消息处理器
        for handler in messageHandlers {
            if handler.canHandleMessage(message) {
                handler.handleMessage(message)
            }
        }
    }
    
    /// 添加扩展连接
    private func addExtensionConnection(_ connection: BrowserExtensionConnection) {
        connectedExtensions.append(connection)
        print("浏览器扩展已连接: \(connection.extensionID)")
    }
    
    /// 移除扩展连接
    private func removeExtensionConnection(_ connection: BrowserExtensionConnection) {
        if let index = connectedExtensions.firstIndex(where: { $0 === connection }) {
            connectedExtensions.remove(at: index)
            print("浏览器扩展已断开连接: \(connection.extensionID)")
        }
    }
    
    /// 关闭所有连接
    private func closeAllConnections() {
        for connection in connectedExtensions {
            connection.close()
        }
        connectedExtensions.removeAll()
    }
}

// MARK: - BrowserExtensionConnection

/// 浏览器扩展连接
class BrowserExtensionConnection {
    
    /// 扩展ID
    let extensionID: String
    
    /// 浏览器类型
    let browserType: BrowserType
    
    /// 连接状态
    var connectionState: ConnectionState
    
    /// 连接时间
    let connectionTime: Date
    
    /// 最后活动时间
    var lastActivityTime: Date
    
    /// 输出流
    private let outputStream: FileHandle
    
    // MARK: - Initialization
    
    init(extensionID: String, browserType: BrowserType, outputStream: FileHandle) {
        self.extensionID = extensionID
        self.browserType = browserType
        self.connectionState = .connected
        self.connectionTime = Date()
        self.lastActivityTime = Date()
        self.outputStream = outputStream
    }
    
    // MARK: - Public Methods
    
    /// 发送消息
    /// - Parameter messageData: 消息数据
    func sendMessage(_ messageData: Data) {
        // 更新最后活动时间
        lastActivityTime = Date()
        
        // 发送消息（本地消息格式）
        // 本地消息格式：4字节长度前缀 + JSON数据
        var length = UInt32(messageData.count).bigEndian
        let lengthData = Data(bytes: &length, count: 4)
        
        // 写入数据
        outputStream.write(lengthData)
        outputStream.write(messageData)
    }
    
    /// 关闭连接
    func close() {
        connectionState = .disconnected
    }
    
    /// 获取连接信息
    func getConnectionInfo() -> [String: Any] {
        return [
            "extensionID": extensionID,
            "browserType": browserType.rawValue,
            "connectionState": connectionState.rawValue,
            "connectionTime": connectionTime,
            "lastActivityTime": lastActivityTime
        ]
    }
}

// MARK: - BrowserExtensionMessage

/// 浏览器扩展消息结构体
struct BrowserExtensionMessage: Codable {
    /// 消息类型
    let type: BrowserExtensionMessageType
    
    /// 消息ID
    let messageID: String
    
    /// 发送者
    let sender: BrowserExtensionSender
    
    /// 接收者
    let receiver: BrowserExtensionReceiver
    
    /// 消息数据
    let data: [String: AnyCodable]?
    
    /// 时间戳
    let timestamp: Date
    
    // MARK: - Initialization
    
    init(type: BrowserExtensionMessageType, data: [String: Any]? = nil) {
        self.type = type
        self.messageID = UUID().uuidString
        self.sender = BrowserExtensionSender(extensionID: "com.macast.core", role: .core)
        self.receiver = BrowserExtensionReceiver(extensionID: "*", role: .extension)
        self.data = data?.mapValues { AnyCodable($0) }
        self.timestamp = Date()
    }
}

// MARK: - BrowserExtensionMessageType

/// 浏览器扩展消息类型枚举
enum BrowserExtensionMessageType: String, Codable {
    case connect = "CONNECT"
    case disconnect = "DISCONNECT"
    case playMedia = "PLAY_MEDIA"
    case pauseMedia = "PAUSE_MEDIA"
    case stopMedia = "STOP_MEDIA"
    case seekMedia = "SEEK_MEDIA"
    case setVolume = "SET_VOLUME"
    case getStatus = "GET_STATUS"
    case statusUpdate = "STATUS_UPDATE"
    case pluginList = "PLUGIN_LIST"
    case protocolList = "PROTOCOL_LIST"
    case error = "ERROR"
    case response = "RESPONSE"
    case ping = "PING"
    case pong = "PONG"
}

// MARK: - BrowserExtensionSender

/// 浏览器扩展消息发送者结构体
struct BrowserExtensionSender: Codable {
    /// 发送者ID
    let extensionID: String
    
    /// 发送者角色
    let role: BrowserExtensionRole
}

// MARK: - BrowserExtensionReceiver

/// 浏览器扩展消息接收者结构体
struct BrowserExtensionReceiver: Codable {
    /// 接收者ID
    let extensionID: String
    
    /// 接收者角色
    let role: BrowserExtensionRole
}

// MARK: - BrowserExtensionRole

/// 浏览器扩展角色枚举
enum BrowserExtensionRole: String, Codable {
    case core = "CORE"
    case `extension` = "EXTENSION"
    case renderer = "RENDERER"
    case `protocol` = "PROTOCOL"
}

// MARK: - BrowserExtensionMessageHandler

/// 浏览器扩展消息处理器协议
protocol BrowserExtensionMessageHandler: AnyObject {
    /// 是否可以处理消息
    /// - Parameter message: 要处理的消息
    func canHandleMessage(_ message: BrowserExtensionMessage) -> Bool
    
    /// 处理消息
    /// - Parameter message: 要处理的消息
    func handleMessage(_ message: BrowserExtensionMessage)
}

// MARK: - BrowserType

/// 浏览器类型枚举
enum BrowserType: String, Codable {
    case chrome = "chrome"
    case firefox = "firefox"
    case safari = "safari"
    case edge = "edge"
    case other = "other"
}

// MARK: - ConnectionState

/// 连接状态枚举
enum ConnectionState: String, Codable {
    case connected = "CONNECTED"
    case connecting = "CONNECTING"
    case disconnecting = "DISCONNECTING"
    case disconnected = "DISCONNECTED"
    case error = "ERROR"
}

// MARK: - NativeMessagingConfig

/// 本地消息主机配置结构体
struct NativeMessagingConfig: Codable {
    /// 主机名称
    let hostName: String
    
    /// 描述
    let description: String
    
    /// 主机路径
    let path: String
    
    /// 通信类型
    let type: String
    
    /// 允许的来源
    let allowedOrigins: [String]
}

// MARK: - AnyCodable

/// 可编码的Any类型
struct AnyCodable: Codable {
    private let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "无法解码值")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "无法编码值"))
        }
    }
    
    var valueRepresentation: Any {
        return value
    }
}
