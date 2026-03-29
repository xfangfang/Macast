import Foundation
import Network

// MARK: - Protocol Protocol

/// 媒体流协议的基本协议
public protocol Protocol: AnyObject {
    
    // MARK: - Basic Properties
    
    /// 协议的唯一标识符
    var identifier: String { get }
    
    /// 协议名称
    var name: String { get }
    
    /// 协议描述
    var description: String { get }
    
    /// 协议版本
    var version: String { get }
    
    /// 协议是否已启用
    var isEnabled: Bool { get set }
    
    // MARK: - Protocol State
    
    /// 协议是否已启动
    var isRunning: Bool { get }
    
    // MARK: - Lifecycle Methods
    
    /// 初始化协议
    init()
    
    /// 启动协议
    func start() throws
    
    /// 停止协议
    func stop() throws
    
    /// 处理请求
    /// - Parameter request: 网络请求
    /// - Returns: 响应对象
    func handleRequest(_ request: NetworkRequest) -> NetworkResponse?
}

// MARK: - NetworkRequest

/// 网络请求结构体
public struct NetworkRequest {
    /// 请求URL
    var url: URL
    
    /// 请求方法
    var method: HTTPMethod
    
    /// 请求头部
    var headers: [String: String]
    
    /// 请求体
    var body: Data?
    
    /// 请求参数
    var parameters: [String: String]
    
    /// 请求来源
    var source: String?
    
    /// 请求时间
    var timestamp: Date
}

// MARK: - NetworkResponse

/// 网络响应结构体
public struct NetworkResponse {
    /// 响应状态码
    var statusCode: Int
    
    /// 响应头部
    var headers: [String: String]
    
    /// 响应体
    var body: Data?
    
    /// 响应时间
    var timestamp: Date
}

// MARK: - HTTPMethod

/// HTTP方法枚举
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case head = "HEAD"
    case options = "OPTIONS"
    case patch = "PATCH"
}

// MARK: - ProtocolManager

/// 协议管理器，负责管理不同的媒体流协议
class ProtocolManager {
    
    // MARK: - Properties
    
    /// 单例实例
    static let shared = ProtocolManager()
    
    /// 已注册的协议
    var protocols: [String: Protocol] = [:]
    
    /// 协议配置
    private var protocolConfigurations: [String: ProtocolConfiguration] = [:]
    
    /// 已注册的URL处理器
    private var urlHandlers: [URLHandler] = []
    
    // MARK: - Initialization
    
    private init() {
        // 加载协议配置
        loadProtocolConfigurations()
        
        // 注册默认协议
        registerDefaultProtocols()
    }
    
    // MARK: - Public Methods
    
    /// 注册协议
    /// - Parameter protocolType: 协议类型
    func registerProtocol(_ protocolType: Protocol.Type) {
        // 创建协议实例
        let protocolInstance = protocolType.init()
        
        // 根据配置启用或禁用协议
        if let configuration = protocolConfigurations[protocolInstance.identifier] {
            protocolInstance.isEnabled = configuration.isEnabled
        } else {
            // 默认启用协议
            protocolInstance.isEnabled = true
            
            // 保存默认配置
            let configuration = ProtocolConfiguration(identifier: protocolInstance.identifier, isEnabled: true)
            protocolConfigurations[protocolInstance.identifier] = configuration
            saveProtocolConfigurations()
        }
        
        // 将协议添加到已注册的协议列表
        protocols[protocolInstance.identifier] = protocolInstance
        
        print("已注册协议: \(protocolInstance.name) (\(protocolInstance.version))")
    }
    
    /// 启动所有已启用的协议
    func startAllProtocols() {
        for protocolInstance in protocols.values {
            if protocolInstance.isEnabled && !protocolInstance.isRunning {
                do {
                    try protocolInstance.start()
                    print("已启动协议: \(protocolInstance.name) (\(protocolInstance.version))")
                } catch {
                    print("启动协议失败: \(protocolInstance.name) - \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// 停止所有协议
    func stopAllProtocols() {
        for protocolInstance in protocols.values {
            if protocolInstance.isRunning {
                do {
                    try protocolInstance.stop()
                    print("已停止协议: \(protocolInstance.name) (\(protocolInstance.version))")
                } catch {
                    print("停止协议失败: \(protocolInstance.name) - \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// 处理请求
    /// - Parameter request: 网络请求
    /// - Returns: 响应对象
    func handleRequest(_ request: NetworkRequest) -> NetworkResponse? {
        // 尝试让每个协议处理请求
        for protocolInstance in protocols.values {
            if protocolInstance.isEnabled && protocolInstance.isRunning {
                if let response = protocolInstance.handleRequest(request) {
                    return response
                }
            }
        }
        
        // 如果没有协议处理请求，返回404响应
        return NetworkResponse(
            statusCode: 404,
            headers: ["Content-Type": "text/plain"],
            body: "Not Found".data(using: .utf8),
            timestamp: Date()
        )
    }
    
    /// 启用协议
    /// - Parameter identifier: 协议标识符
    func enableProtocol(withIdentifier identifier: String) throws {
        guard let protocolInstance = protocols[identifier] else {
            throw ProtocolError.protocolNotFound
        }
        
        protocolInstance.isEnabled = true
        
        // 更新配置
        if var configuration = protocolConfigurations[identifier] {
            configuration.isEnabled = true
            protocolConfigurations[identifier] = configuration
            saveProtocolConfigurations()
        }
        
        // 如果协议未启动，启动协议
        if !protocolInstance.isRunning {
            try protocolInstance.start()
        }
    }
    
    /// 禁用协议
    /// - Parameter identifier: 协议标识符
    func disableProtocol(withIdentifier identifier: String) throws {
        guard let protocolInstance = protocols[identifier] else {
            throw ProtocolError.protocolNotFound
        }
        
        protocolInstance.isEnabled = false
        
        // 更新配置
        if var configuration = protocolConfigurations[identifier] {
            configuration.isEnabled = false
            protocolConfigurations[identifier] = configuration
            saveProtocolConfigurations()
        }
        
        // 如果协议正在运行，停止协议
        if protocolInstance.isRunning {
            try protocolInstance.stop()
        }
    }
    
    /// 获取所有已注册的协议
    func getAllProtocols() -> [Protocol] {
        return Array(protocols.values)
    }
    
    /// 获取指定标识符的协议
    func getProtocol(withIdentifier identifier: String) -> Protocol? {
        return protocols[identifier]
    }
    
    /// 获取所有已启用的协议
    func getEnabledProtocols() -> [Protocol] {
        return protocols.values.filter { $0.isEnabled }
    }
    
    // MARK: - Private Methods
    
    /// 注册默认协议
    private func registerDefaultProtocols() {
        // 这里可以注册默认支持的协议
        // 例如：DLNAProtocol、AirPlayProtocol、ChromecastProtocol等
        if #available(macOS 11.0, *) {
            registerProtocol(DLNAProtocol.self)
        }
        print("注册默认协议完成")
    }
    
    /// 加载协议配置
    private func loadProtocolConfigurations() {
        let userDefaults = UserDefaults.standard
        
        if let configurationsData = userDefaults.data(forKey: "protocolConfigurations") {
            do {
                let configurations = try JSONDecoder().decode([String: ProtocolConfiguration].self, from: configurationsData)
                protocolConfigurations = configurations
            } catch {
                print("加载协议配置失败: \(error.localizedDescription)")
            }
        }
    }
    
    /// 保存协议配置
    private func saveProtocolConfigurations() {
        let userDefaults = UserDefaults.standard
        
        do {
            let data = try JSONEncoder().encode(protocolConfigurations)
            userDefaults.set(data, forKey: "protocolConfigurations")
            userDefaults.synchronize()
        } catch {
            print("保存协议配置失败: \(error.localizedDescription)")
        }
    }
}

// MARK: - ProtocolConfiguration

/// 协议配置
struct ProtocolConfiguration: Codable {
    var identifier: String
    var isEnabled: Bool
}

// MARK: - ProtocolError

enum ProtocolError: Error, LocalizedError {
    case protocolNotFound
    case protocolAlreadyRegistered
    case protocolStartFailed
    case protocolStopFailed
    case invalidProtocol
    
    var errorDescription: String? {
        switch self {
        case .protocolNotFound:
            return "协议未找到"
        case .protocolAlreadyRegistered:
            return "协议已注册"
        case .protocolStartFailed:
            return "协议启动失败"
        case .protocolStopFailed:
            return "协议停止失败"
        case .invalidProtocol:
            return "无效的协议"
        }
    }
}

// MARK: - URLHandler Protocol

/// URL处理器协议
public protocol URLHandler: AnyObject {
    /// 处理URL
    /// - Parameter url: 要处理的URL
    /// - Returns: 是否成功处理
    func handleURL(_ url: URL) -> Bool
}

// MARK: - Protocol Extension

extension Protocol {
    /// 协议启动完成
    func protocolDidStart() {
        print("协议已启动: \(name) (\(version))")
    }
    
    /// 协议停止完成
    func protocolDidStop() {
        print("协议已停止: \(name) (\(version))")
    }
    
    /// 协议处理请求
    func protocolDidHandleRequest(_ request: NetworkRequest) -> NetworkResponse? {
        // 默认实现不处理任何请求
        return nil
    }
}

// MARK: - ProtocolManager URL Handling Extension

extension ProtocolManager {
    
    /// 注册URL处理器
    /// - Parameter handler: URL处理器
    func registerURLHandler(_ handler: URLHandler) {
        if !urlHandlers.contains(where: { $0 === handler }) {
            urlHandlers.append(handler)
            print("已注册URL处理器: \(type(of: handler))")
        }
    }
    
    /// 取消注册URL处理器
    /// - Parameter handler: URL处理器
    func unregisterURLHandler(_ handler: URLHandler) {
        if let index = urlHandlers.firstIndex(where: { $0 === handler }) {
            urlHandlers.remove(at: index)
            print("已取消注册URL处理器: \(type(of: handler))")
        }
    }
    
    /// 处理URL
    /// - Parameter url: 要处理的URL
    /// - Returns: 是否成功处理
    func handleURL(_ url: URL) -> Bool {
        for handler in urlHandlers {
            if handler.handleURL(url) {
                return true
            }
        }
        return false
    }
}

// MARK: - HTTPMethod Extension

extension HTTPMethod: Codable {
}

// MARK: - NetworkRequest Extension

extension NetworkRequest: Codable {
    private enum CodingKeys: String, CodingKey {
        case url, method, headers, body, parameters, source, timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(URL.self, forKey: .url)
        method = try container.decode(HTTPMethod.self, forKey: .method)
        headers = try container.decode([String: String].self, forKey: .headers)
        body = try container.decodeIfPresent(Data.self, forKey: .body)
        parameters = try container.decode([String: String].self, forKey: .parameters)
        source = try container.decodeIfPresent(String.self, forKey: .source)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url, forKey: .url)
        try container.encode(method, forKey: .method)
        try container.encode(headers, forKey: .headers)
        try container.encodeIfPresent(body, forKey: .body)
        try container.encode(parameters, forKey: .parameters)
        try container.encodeIfPresent(source, forKey: .source)
        try container.encode(timestamp, forKey: .timestamp)
    }
}

// MARK: - NetworkResponse Extension

extension NetworkResponse: Codable {
    private enum CodingKeys: String, CodingKey {
        case statusCode, headers, body, timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        statusCode = try container.decode(Int.self, forKey: .statusCode)
        headers = try container.decode([String: String].self, forKey: .headers)
        body = try container.decodeIfPresent(Data.self, forKey: .body)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(statusCode, forKey: .statusCode)
        try container.encode(headers, forKey: .headers)
        try container.encodeIfPresent(body, forKey: .body)
        try container.encode(timestamp, forKey: .timestamp)
    }
}
