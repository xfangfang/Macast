import Foundation
import Network

// SSDP协议相关常量
struct SSDPConstants {
    static let multicastGroup = "239.255.255.250"
    static let multicastPort: UInt16 = 1900
    static let ttl: UInt8 = 4
    static let maxResponseWaitTime: TimeInterval = 5.0
    static let notificationInterval: TimeInterval = 30.0
    
    // SSDP消息类型
    static let ssdpAll = "ssdp:all"
    static let upnpRootDevice = "upnp:rootdevice"
    static let mediaRenderer = "urn:schemas-upnp-org:device:MediaRenderer:1"
    static let connectionManager = "urn:schemas-upnp-org:service:ConnectionManager:1"
    static let avTransport = "urn:schemas-upnp-org:service:AVTransport:1"
    static let renderingControl = "urn:schemas-upnp-org:service:RenderingControl:1"
}

// SSDP服务器类
@available(macOS 11.0, *)
class SSDPServer {
    
    // MARK: - Properties
    
    private var udpListener: NWListener?
    private var multicastGroup: NWMulticastGroup?
    private var browser: NWConnection?
    private var timer: Timer?
    
    var serverURL: URL?
    var serverUUID: String
    var deviceDescriptionPath: String = "/description.xml"

    private var searchTargets: [(st: String, usn: String)] {
        [
            (SSDPConstants.upnpRootDevice, "uuid:\(serverUUID)::\(SSDPConstants.upnpRootDevice)"),
            (SSDPConstants.mediaRenderer, "uuid:\(serverUUID)::\(SSDPConstants.mediaRenderer)"),
            (SSDPConstants.connectionManager, "uuid:\(serverUUID)::\(SSDPConstants.connectionManager)"),
            (SSDPConstants.avTransport, "uuid:\(serverUUID)::\(SSDPConstants.avTransport)"),
            (SSDPConstants.renderingControl, "uuid:\(serverUUID)::\(SSDPConstants.renderingControl)")
        ]
    }
    
    // MARK: - Initialization
    
    init() {
        // 生成唯一的设备UUID
        serverUUID = UUID().uuidString
    }
    
    // MARK: - Public Methods
    
    // 启动SSDP服务器
    func start() {
        guard let group = try? NWMulticastGroup(for: [.hostPort(host: NWEndpoint.Host(SSDPConstants.multicastGroup), port: NWEndpoint.Port(integerLiteral: SSDPConstants.multicastPort))], from: nil)
        else {
            print("无法创建多播组")
            return
        }
        
        multicastGroup = group
        
        // 设置UDP监听器
        do {
            udpListener = try NWListener(using: .udp, on: NWEndpoint.Port(integerLiteral: SSDPConstants.multicastPort))
            udpListener?.stateUpdateHandler = { [weak self] state in
                self?.handleListenerState(state)
            }
            
            // 设置传入连接的处理程序
            udpListener?.newConnectionHandler = { [weak self] connection in
                self?.handleIncomingConnection(connection)
            }
            
            udpListener?.start(queue: .global())
        } catch {
            print("无法创建UDP监听器: \(error)")
            return
        }
        
        // 开始发送通知
        startSendingNotifications()
        
        print("SSDP服务器启动成功")
    }
    
    // 停止SSDP服务器
    func stop() {
        timer?.invalidate()
        timer = nil
        
        browser?.cancel()
        browser = nil
        
        udpListener?.cancel()
        udpListener = nil
        
        print("SSDP服务器已停止")
    }
    
    // MARK: - Private Methods
    
    // 处理监听器状态变化
    private func handleListenerState(_ state: NWListener.State) {
        switch state {
        case .ready:
            print("UDP监听器已准备就绪")
        case .waiting(let error):
            print("UDP监听器等待中: \(error)")
        case .failed(let error):
            print("UDP监听器失败: \(error)")
            udpListener?.cancel()
        default:
            break
        }
    }
    
    // 处理传入连接
    private func handleIncomingConnection(_ connection: NWConnection) {
        connection.receiveMessage { [weak self] data, context, isComplete, error in
            if let data = data, let message = String(data: data, encoding: .utf8) {
                self?.handleSSDPMessage(message, from: connection)
            }
            
            if isComplete {
                connection.cancel()
            } else {
                self?.handleIncomingConnection(connection)
            }
        }
        
        connection.start(queue: .global())
    }
    
    // 处理SSDP消息
    private func handleSSDPMessage(_ message: String, from connection: NWConnection) {
        print("收到SSDP消息: \n\(message)")
        
        // 检查是否是M-SEARCH请求
        if message.contains("M-SEARCH") {
            handleMSearchRequest(message, from: connection)
        }
    }
    
    // 处理M-SEARCH请求
    private func handleMSearchRequest(_ request: String, from connection: NWConnection) {
        // 解析ST（Search Target）头
        let stRegex = try! NSRegularExpression(pattern: "(?i)^ST:\\s*(.+)$", options: .anchorsMatchLines)
        let range = NSRange(location: 0, length: request.utf16.count)
        guard let stMatch = stRegex.firstMatch(in: request, options: [], range: range),
              let stRange = Range(stMatch.range(at: 1), in: request)
        else {
            return
        }
        
        let searchTarget = String(request[stRange])
        
        // 检查是否匹配我们的服务
        if searchTarget == SSDPConstants.ssdpAll {
            for target in searchTargets {
                sendMSearchResponse(to: connection, searchTarget: target.st, usn: target.usn)
            }
            return
        }

        if let target = searchTargets.first(where: { $0.st == searchTarget }) {
            sendMSearchResponse(to: connection, searchTarget: target.st, usn: target.usn)
        }
    }
    
    // 发送M-SEARCH响应
    private func sendMSearchResponse(to connection: NWConnection, searchTarget: String, usn: String) {
        guard let serverURL = serverURL else {
            return
        }
        
        // 构建响应消息
        let response = "HTTP/1.1 200 OK\r\n" +
                      "CACHE-CONTROL: max-age=1800\r\n" +
                      "DATE: \(formatDate(Date()))\r\n" +
                      "EXT:\r\n" +
                      "LOCATION: \(serverURL.absoluteString)\(deviceDescriptionPath)\r\n" +
                      "SERVER: MacOS/10.15 UPnP/1.1 Macast/1.0\r\n" +
                      "ST: \(searchTarget)\r\n" +
                      "USN: \(usn)\r\n" +
                      "\r\n"
        
        if let data = response.data(using: .utf8) {
            connection.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    print("发送M-SEARCH响应失败: \(error)")
                }
            })
        }
    }
    
    // 开始发送通知
    private func startSendingNotifications() {
        timer = Timer.scheduledTimer(withTimeInterval: SSDPConstants.notificationInterval, repeats: true) { [weak self] _ in
            self?.sendSSDPNotification()
        }
        
        // 立即发送一次通知
        sendSSDPNotification()
    }
    
    // 发送SSDP通知
    private func sendSSDPNotification() {
        guard let serverURL = serverURL else {
            return
        }
        
        for target in searchTargets {
            let notify = "NOTIFY * HTTP/1.1\r\n" +
                         "HOST: \(SSDPConstants.multicastGroup):\(SSDPConstants.multicastPort)\r\n" +
                         "CACHE-CONTROL: max-age=1800\r\n" +
                         "LOCATION: \(serverURL.absoluteString)\(deviceDescriptionPath)\r\n" +
                         "NT: \(target.st)\r\n" +
                         "NTS: ssdp:alive\r\n" +
                         "SERVER: MacOS/10.15 UPnP/1.1 Macast/1.0\r\n" +
                         "USN: \(target.usn)\r\n" +
                         "\r\n"

            if let data = notify.data(using: .utf8), multicastGroup != nil {
                let connection = NWConnection(to: NWEndpoint.hostPort(host: NWEndpoint.Host(SSDPConstants.multicastGroup), port: NWEndpoint.Port(integerLiteral: SSDPConstants.multicastPort)), using: .udp)
                connection.stateUpdateHandler = { state in
                    if case .ready = state {
                        connection.send(content: data, completion: NWConnection.SendCompletion.contentProcessed { error in
                            if let error = error {
                                print("发送SSDP通知失败: \(error)")
                            }
                            connection.cancel()
                        })
                    } else if case .failed(let error) = state {
                        print("多播连接失败: \(error)")
                        connection.cancel()
                    }
                }

                connection.start(queue: DispatchQueue.global())
            }
        }
    }
    
    // 格式化日期为HTTP日期格式
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        return formatter.string(from: date)
    }
}
