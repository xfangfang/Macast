import Foundation
import Network

// AirPlay协议相关常量
struct AirPlayConstants {
    static let serviceType = "_airplay._tcp"
    static let serviceName = "Macast"
    static let airTunesServiceType = "_raop._tcp"
    static let bonjourPort: UInt16 = 7000
    static let maxConnections = 5
    
    // AirPlay消息类型
    static let play = "play"
    static let pause = "pause"
    static let stop = "stop"
    static let seek = "seek"
}

// AirPlay服务器类
@available(macOS 11.0, *)
class AirPlayServer {
    
    // MARK: - Properties
    
    var serverURL: URL?
    var serverUUID: String
    
    private var bonjourBrowser: NetServiceBrowser?
    private var bonjourService: NetService?
    private var tcpListener: NWListener?
    private var connections: [NWConnection] = []
    
    // MARK: - Initialization
    
    init() {
        // 生成唯一的设备UUID
        serverUUID = UUID().uuidString
    }
    
    // MARK: - Public Methods
    
    // 启动AirPlay服务器
    func start() throws {
        // 注册Bonjour服务
        registerBonjourService()
        
        // 设置TCP监听器
        do {
            tcpListener = try NWListener(using: .tcp, on: NWEndpoint.Port(integerLiteral: AirPlayConstants.bonjourPort))
            tcpListener?.stateUpdateHandler = { [weak self] state in
                self?.handleListenerState(state)
            }
            
            // 设置传入连接的处理程序
            tcpListener?.newConnectionHandler = { [weak self] connection in
                self?.handleIncomingConnection(connection)
            }
            
            tcpListener?.start(queue: .global())
        } catch {
            print("无法创建TCP监听器: error)")
            throw AirPlayError.serverStartFailed
        }
        
        print("AirPlay服务器启动成功")
    }
    
    // 停止AirPlay服务器
    func stop() {
        // 注销Bonjour服务
        bonjourService?.stop()
        bonjourService = nil
        
        // 停止TCP监听器
        tcpListener?.cancel()
        tcpListener = nil
        
        // 关闭所有连接
        for connection in connections {
            connection.cancel()
        }
        connections.removeAll()
        
        print("AirPlay服务器已停止")
    }
    
    // 处理请求
    func handleRequest(_ request: NetworkRequest) -> NetworkResponse? {
        // 处理AirPlay特定的HTTP请求
        let path = request.url.path
        switch path {
        case "/play":
            return handlePlayRequest(request)
        case "/pause":
            return handlePauseRequest(request)
        case "/stop":
            return handleStopRequest(request)
        case "/seek":
            return handleSeekRequest(request)
        case "/server-info":
            return handleServerInfoRequest(request)
        default:
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    // 注册Bonjour服务
    private func registerBonjourService() {
        // 注册AirPlay服务
        bonjourService = NetService(domain: "local.", type: AirPlayConstants.serviceType, name: AirPlayConstants.serviceName, port: Int32(AirPlayConstants.bonjourPort))
        
        // 设置TXTRecord
        var txtRecord: [String: String] = [
            "deviceid": serverUUID,
            "features": "0x5A7FFFF7,0x0",
            "model": "Macast",
            "srcvers": "220.68"
        ]
        
        if let serverURL = serverURL {
            txtRecord["deviceconfig"] = serverURL.absoluteString
        }
        
        bonjourService?.setTXTRecord(createTXTRecord(from: txtRecord))
        bonjourService?.publish()
        
        print("Bonjour服务已注册: AirPlayConstants.serviceName).AirPlayConstants.serviceType).local.")
    }
    
    // 创建TXT记录数据
    private func createTXTRecord(from dictionary: [String: String]) -> Data {
        var txtRecordData = Data()
        
        for (key, value) in dictionary {
            let keyLength = UInt8(key.count)
            txtRecordData.append(keyLength)
            txtRecordData.append(key.data(using: .utf8)!) // 强制解包，因为字典中的值都是有效的
            txtRecordData.append(value.data(using: .utf8)!) // 强制解包
        }
        
        return txtRecordData
    }
    
    // 处理监听器状态变化
    private func handleListenerState(_ state: NWListener.State) {
        switch state {
        case .ready:
            print("TCP监听器已准备就绪，端口: String(describing: tcpListener?.port))")
        case .waiting(let error):
            print("TCP监听器等待中: error.localizedDescription)")
        case .failed(let error):
            print("TCP监听器失败: error.localizedDescription)")
            tcpListener?.cancel()
        case .cancelled:
            print("TCP监听器已取消")
        default:
            break
        }
    }
    
    // 处理传入连接
    private func handleIncomingConnection(_ connection: NWConnection) {
        // 限制最大连接数
        if connections.count >= AirPlayConstants.maxConnections {
            connection.cancel()
            return
        }
        
        connections.append(connection)
        
        // 设置连接状态更新处理程序
        connection.stateUpdateHandler = { [weak self] state in
            self?.handleConnectionState(state, connection: connection)
        }
        
        // 设置传入数据处理程序
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024 * 1024) { [weak self] data, _, isComplete, error in
            self?.handleIncomingData(data, connection: connection)
        }
        
        connection.start(queue: .global())
    }
    
    // 处理连接状态变化
    private func handleConnectionState(_ state: NWConnection.State, connection: NWConnection) {
        switch state {
        case .ready:
            print("AirPlay连接已建立")
        case .failed(let error):
            print("AirPlay连接失败: error.localizedDescription)")
            removeConnection(connection)
        case .cancelled:
            print("AirPlay连接已取消")
            removeConnection(connection)
        default:
            break
        }
    }
    
    // 处理传入数据
    private func handleIncomingData(_ data: Data?, connection: NWConnection) {
        guard let data = data else {
            return
        }
        
        // 处理AirPlay协议数据
        print("收到AirPlay数据: data.count) 字节")
        
        // 继续接收数据
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024 * 1024) { [weak self] data, _, isComplete, error in
            self?.handleIncomingData(data, connection: connection)
        }
    }
    
    // 移除连接
    private func removeConnection(_ connection: NWConnection) {
        if let index = connections.firstIndex(where: { $0 === connection }) {
            connections.remove(at: index)
        }
    }
    
    // MARK: - Request Handlers
    
    // 处理播放请求
    private func handlePlayRequest(_ request: NetworkRequest) -> NetworkResponse? {
        print("收到AirPlay播放请求")
        // TODO: 实现播放逻辑
        return NetworkResponse(statusCode: 200, headers: [:], body: "OK".data(using: .utf8), timestamp: Date())
    }
    
    // 处理暂停请求
    private func handlePauseRequest(_ request: NetworkRequest) -> NetworkResponse? {
        print("收到AirPlay暂停请求")
        // TODO: 实现暂停逻辑
        return NetworkResponse(statusCode: 200, headers: [:], body: "OK".data(using: .utf8), timestamp: Date())
    }
    
    // 处理停止请求
    private func handleStopRequest(_ request: NetworkRequest) -> NetworkResponse? {
        print("收到AirPlay停止请求")
        // TODO: 实现停止逻辑
        return NetworkResponse(statusCode: 200, headers: [:], body: "OK".data(using: .utf8), timestamp: Date())
    }
    
    // 处理 seek 请求
    private func handleSeekRequest(_ request: NetworkRequest) -> NetworkResponse? {
        print("收到AirPlay seek请求")
        // TODO: 实现 seek 逻辑
        return NetworkResponse(statusCode: 200, headers: [:], body: "OK".data(using: .utf8), timestamp: Date())
    }
    
    // 处理服务器信息请求
    private func handleServerInfoRequest(_ request: NetworkRequest) -> NetworkResponse? {
        print("收到AirPlay服务器信息请求")
        let serverInfo = [
            "deviceid": serverUUID,
            "model": "Macast",
            "version": "1.0.0",
            "features": "0x5A7FFFF7,0x0"
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: serverInfo, options: [])
            return NetworkResponse(statusCode: 200, headers: ["Content-Type": "application/json"], body: jsonData, timestamp: Date())
        } catch {
            return NetworkResponse(statusCode: 500, headers: [:], body: "Internal Server Error".data(using: .utf8), timestamp: Date())
        }
    }
}

// AirPlay错误枚举
enum AirPlayError: Error {
    case serverStartFailed
    case invalidRequest
    case unsupportedFeature
    case connectionFailed
    case mediaPlaybackFailed
    
    var localizedDescription: String {
        switch self {
        case .serverStartFailed:
            return "AirPlay服务器启动失败"
        case .invalidRequest:
            return "无效的AirPlay请求"
        case .unsupportedFeature:
            return "不支持的AirPlay功能"
        case .connectionFailed:
            return "AirPlay连接失败"
        case .mediaPlaybackFailed:
            return "媒体播放失败"
        }
    }
}
