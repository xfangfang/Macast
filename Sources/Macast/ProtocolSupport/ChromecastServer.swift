import Foundation
import Network
import CFNetwork

// MARK: - ChromecastServer

/// Chromecast服务器实现
@available(macOS 11.0, *)
class ChromecastServer: NSObject {
    
    // MARK: - Basic Properties
    
    /// 服务器URL
    var serverURL: URL?
    
    /// mDNS服务类型
    static let serviceType = "_googlecast._tcp."
    
    /// mDNS服务名称
    static let serviceName = "Macast"
    
    // MARK: - Server State
    
    /// 服务器是否正在运行
    private var isRunning: Bool = false
    
    // MARK: - Network Components
    
    /// mDNS服务
    private var netService: NetService?
    
    /// mDNS服务浏览器
    private var netServiceBrowser: NetServiceBrowser?
    
    /// TCP监听器
    private var listener: NWListener?
    
    /// 活动连接
    private var connections: [NWConnection] = []
    
    // MARK: - Initialization
    
    override init() {
        // 初始化mDNS服务和TCP监听器
        super.init()
    }
    
    // MARK: - Server Lifecycle
    
    /// 启动服务器
    func start() throws {
        if !isRunning {
            // 启动TCP监听器
            try startTCPListener()
            
            // 注册mDNS服务
            registerMDNSService()
            
            // 更新运行状态
            isRunning = true
            
            print("Chromecast服务器已启动")
        }
    }
    
    /// 停止服务器
    func stop() {
        if isRunning {
            // 停止TCP监听器
            stopTCPListener()
            
            // 取消注册mDNS服务
            deregisterMDNSService()
            
            // 关闭所有连接
            closeAllConnections()
            
            // 更新运行状态
            isRunning = false
            
            print("Chromecast服务器已停止")
        }
    }
    
    // MARK: - mDNS Service
    
    /// 注册mDNS服务
    private func registerMDNSService() {
        // 创建mDNS服务
        netService = NetService(domain: "local.", 
                              type: ChromecastServer.serviceType, 
                              name: ChromecastServer.serviceName, 
                              port: 8009)
        
        // 设置服务属性
        var serviceProperties = [String: Data]()
        
        // Chromecast设备信息
        let deviceInfo: [String: Any] = [
            "id": UUID().uuidString,
            "md": "Macast",
            "fn": "Macast",
            "ca": 4,
            "ic": "/setup/icon.png",
            "ve": "0"
        ]
        
        // 序列化设备信息
        if let deviceInfoData = try? JSONSerialization.data(withJSONObject: deviceInfo) {
            serviceProperties["id"] = UUID().uuidString.data(using: .utf8)
            serviceProperties["cd"] = "0000000000000001".data(using: .utf8)
            serviceProperties["rm"] = "".data(using: .utf8)
            serviceProperties["md"] = "Macast".data(using: .utf8)
            serviceProperties["fn"] = "Macast".data(using: .utf8)
            serviceProperties["ca"] = "4".data(using: .utf8)
            serviceProperties["ic"] = "/setup/icon.png".data(using: .utf8)
            serviceProperties["ve"] = "0".data(using: .utf8)
        }
        
        // 设置服务属性
        if let txtData = TXTRecordDataWithDictionary(serviceProperties) {
            netService?.setTXTRecord(txtData)
        }
        
        // 设置服务代理
        netService?.delegate = self
        
        // 发布服务
        netService?.publish(options: [.listenForConnections])
        
        print("Chromecast mDNS服务已注册")
    }
    
    /// 取消注册mDNS服务
    private func deregisterMDNSService() {
        // 停止服务
        netService?.stop()
        netService?.delegate = nil
        netService = nil
        
        // 停止服务浏览器
        netServiceBrowser?.stop()
        netServiceBrowser?.delegate = nil
        netServiceBrowser = nil
        
        print("Chromecast mDNS服务已取消注册")
    }
    
    // MARK: - TCP Listener
    
    /// 启动TCP监听器
    private func startTCPListener() throws {
        // 创建TCP监听器
        listener = try NWListener(using: .tcp, on: NWEndpoint.Port(integerLiteral: 8009))
        
        // 设置监听器状态变化处理
        listener?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("Chromecast TCP监听器已准备好")
            case .failed(let error):
                print("Chromecast TCP监听器失败: \(error)")
                self?.stop()
            case .cancelled:
                print("Chromecast TCP监听器已取消")
            default:
                break
            }
        }
        
        // 设置新连接处理
        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleNewConnection(connection)
        }
        
        // 启动监听器
        listener?.start(queue: DispatchQueue(label: "com.macast.chromecast.tcp.listener"))
        
        print("Chromecast TCP监听器已启动")
    }
    
    /// 停止TCP监听器
    private func stopTCPListener() {
        // 取消监听器
        listener?.cancel()
        listener = nil
        
        print("Chromecast TCP监听器已停止")
    }
    
    // MARK: - Connection Handling
    
    /// 处理新连接
    private func handleNewConnection(_ connection: NWConnection) {
        // 添加连接到连接列表
        connections.append(connection)
        
        // 设置连接状态变化处理
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("Chromecast连接已准备好")
                self?.receiveData(connection)
            case .failed(let error):
                print("Chromecast连接失败: \(error)")
                self?.removeConnection(connection)
            case .cancelled:
                print("Chromecast连接已取消")
                self?.removeConnection(connection)
            default:
                break
            }
        }
        
        // 启动连接
        connection.start(queue: DispatchQueue(label: "com.macast.chromecast.connection"))
    }
    
    /// 接收数据
    private func receiveData(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, context, isComplete, error in
            if let data = data, !data.isEmpty {
                // 处理接收到的数据
                self?.handleReceivedData(data, connection: connection)
            }
            
            if isComplete {
                // 连接已完成
                self?.removeConnection(connection)
            } else if error == nil {
                // 继续接收数据
                self?.receiveData(connection)
            }
        }
    }
    
    /// 处理接收到的数据
    private func handleReceivedData(_ data: Data, connection: NWConnection) {
        // 解析Chromecast请求
        if let request = parseChromecastRequest(data) {
            // 处理请求
            if let response = handleRequest(request) {
                // 发送响应
                sendResponse(response, connection: connection)
            }
        }
    }
    
    /// 发送响应
    private func sendResponse(_ response: NetworkResponse, connection: NWConnection) {
        // 构建响应数据
        if let responseData = response.body as? Data {
            connection.send(content: responseData, completion: .contentProcessed { error in
                if let error = error {
                    print("Chromecast响应发送失败: \(error)")
                }
            })
        }
    }
    
    /// 移除连接
    private func removeConnection(_ connection: NWConnection) {
        if let index = connections.firstIndex(where: { $0 === connection }) {
            connections.remove(at: index)
        }
        connection.cancel()
    }
    
    /// 关闭所有连接
    private func closeAllConnections() {
        for connection in connections {
            connection.cancel()
        }
        connections.removeAll()
    }
    
    // MARK: - Request Handling
    
    /// 解析Chromecast请求
    private func parseChromecastRequest(_ data: Data) -> NetworkRequest? {
        // 尝试解析JSON数据
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            // 创建请求对象
            if let url = serverURL?.appendingPathComponent("/chromecast") {
                let jsonData = try? JSONSerialization.data(withJSONObject: json)
                return NetworkRequest(
                    url: url,
                    method: .post,
                    headers: [:],
                    body: jsonData,
                    parameters: [:],
                    source: nil,
                    timestamp: Date()
                )
            }
        }
        return nil
    }
    
    /// 处理Chromecast请求
    func handleRequest(_ request: NetworkRequest) -> NetworkResponse? {
        // 获取请求路径
        let path = request.url.path
        
        // 根据路径处理不同的请求
        switch path {
        case "/chromecast":
            return handleChromecastCommand(request)
        default:
            return NetworkResponse(statusCode: 404, headers: [:], body: nil, timestamp: Date())
        }
    }
    
    /// 处理Chromecast命令
    private func handleChromecastCommand(_ request: NetworkRequest) -> NetworkResponse? {
        // 解析命令
        if let body = request.body as? [String: Any] {
            // 根据命令类型处理
            if let type = body["type"] as? String {
                switch type {
                case "CONNECT":
                    return handleConnectCommand(body)
                case "LOAD":
                    return handleLoadCommand(body)
                case "PLAY":
                    return handlePlayCommand(body)
                case "PAUSE":
                    return handlePauseCommand(body)
                case "STOP":
                    return handleStopCommand(body)
                case "SEEK":
                    return handleSeekCommand(body)
                case "SET_VOLUME":
                    return handleSetVolumeCommand(body)
                default:
                    break
                }
            }
        }
        
        // 返回默认响应
        let responseBody = ["status": "ERROR", "message": "Unknown command"]
        if let responseData = try? JSONSerialization.data(withJSONObject: responseBody) {
            return NetworkResponse(statusCode: 200, headers: [:], body: responseData, timestamp: Date())
        }
        
        return nil
    }
    
    /// 处理连接命令
    private func handleConnectCommand(_ body: [String: Any]) -> NetworkResponse? {
        // 返回连接成功响应
        let responseBody = ["status": "SUCCESS", "message": "Connected"]
        if let responseData = try? JSONSerialization.data(withJSONObject: responseBody) {
            return NetworkResponse(statusCode: 200, headers: [:], body: responseData, timestamp: Date())
        }
        return nil
    }
    
    /// 处理加载命令
    private func handleLoadCommand(_ body: [String: Any]) -> NetworkResponse? {
        // 返回加载成功响应
        let responseBody = ["status": "SUCCESS", "message": "Media loaded"]
        if let responseData = try? JSONSerialization.data(withJSONObject: responseBody) {
            return NetworkResponse(statusCode: 200, headers: [:], body: responseData, timestamp: Date())
        }
        return nil
    }
    
    /// 处理播放命令
    private func handlePlayCommand(_ body: [String: Any]) -> NetworkResponse? {
        // 返回播放成功响应
        let responseBody = ["status": "SUCCESS", "message": "Playing"]
        if let responseData = try? JSONSerialization.data(withJSONObject: responseBody) {
            return NetworkResponse(statusCode: 200, headers: [:], body: responseData, timestamp: Date())
        }
        return nil
    }
    
    /// 处理暂停命令
    private func handlePauseCommand(_ body: [String: Any]) -> NetworkResponse? {
        // 返回暂停成功响应
        let responseBody = ["status": "SUCCESS", "message": "Paused"]
        if let responseData = try? JSONSerialization.data(withJSONObject: responseBody) {
            return NetworkResponse(statusCode: 200, headers: [:], body: responseData, timestamp: Date())
        }
        return nil
    }
    
    /// 处理停止命令
    private func handleStopCommand(_ body: [String: Any]) -> NetworkResponse? {
        // 返回停止成功响应
        let responseBody = ["status": "SUCCESS", "message": "Stopped"]
        if let responseData = try? JSONSerialization.data(withJSONObject: responseBody) {
            return NetworkResponse(statusCode: 200, headers: [:], body: responseData, timestamp: Date())
        }
        return nil
    }
    
    /// 处理跳转命令
    private func handleSeekCommand(_ body: [String: Any]) -> NetworkResponse? {
        // 返回跳转成功响应
        let responseBody = ["status": "SUCCESS", "message": "Seeked"]
        if let responseData = try? JSONSerialization.data(withJSONObject: responseBody) {
            return NetworkResponse(statusCode: 200, headers: [:], body: responseData, timestamp: Date())
        }
        return nil
    }
    
    /// 处理设置音量命令
    private func handleSetVolumeCommand(_ body: [String: Any]) -> NetworkResponse? {
        // 返回设置音量成功响应
        let responseBody = ["status": "SUCCESS", "message": "Volume set"]
        if let responseData = try? JSONSerialization.data(withJSONObject: responseBody) {
            return NetworkResponse(statusCode: 200, headers: [:], body: responseData, timestamp: Date())
        }
        return nil
    }
}

// MARK: - NetServiceDelegate

@available(macOS 11.0, *)
extension ChromecastServer: NetServiceDelegate {
    
    /// mDNS服务发布成功
    func netServiceDidPublish(_ sender: NetService) {
        print("Chromecast mDNS服务发布成功")
    }
    
    /// mDNS服务发布失败
    func netService(_ sender: NetService, didNotPublish errorDict: [String: NSNumber]) {
        print("Chromecast mDNS服务发布失败: \(errorDict)")
    }
    
    /// mDNS服务解决成功
    func netServiceDidResolveAddress(_ sender: NetService) {
        print("Chromecast mDNS服务解决成功")
    }
    
    /// mDNS服务解决失败
    func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        print("Chromecast mDNS服务解决失败: \(errorDict)")
    }
}

// MARK: - ChromecastError

/// Chromecast错误枚举
enum ChromecastError: Error {
    case serverStartFailed
    case serviceRegistrationFailed
    case connectionFailed
    case requestParsingFailed
    case commandHandlingFailed
    case responseGenerationFailed
    
    var localizedDescription: String {
        switch self {
        case .serverStartFailed:
            return "Chromecast服务器启动失败"
        case .serviceRegistrationFailed:
            return "Chromecast服务注册失败"
        case .connectionFailed:
            return "Chromecast连接失败"
        case .requestParsingFailed:
            return "Chromecast请求解析失败"
        case .commandHandlingFailed:
            return "Chromecast命令处理失败"
        case .responseGenerationFailed:
            return "Chromecast响应生成失败"
        }
    }
}

// MARK: - TXTRecord Helper Functions

/// 将字典转换为TXTRecord数据
/// - Parameter dictionary: 键值对字典
/// - Returns: TXTRecord数据
func TXTRecordDataWithDictionary(_ dictionary: [String: Data]) -> Data? {
    // 简单实现：将键值对转换为字符串格式 ["key1=value1", "key2=value2"]
    var txtRecord = Data()
    
    for (key, value) in dictionary {
        // 键值对格式：key=value
        let keyValueString = "\(key)=\(String(data: value, encoding: .utf8) ?? "")"
        
        // 确保键值对长度符合要求
        guard keyValueString.count <= 255 else {
            continue
        }
        
        // 添加键值对长度字节
        txtRecord.append(UInt8(keyValueString.count))
        
        // 添加键值对数据
        txtRecord.append(keyValueString.data(using: .utf8) ?? Data())
    }
    
    return txtRecord
}
