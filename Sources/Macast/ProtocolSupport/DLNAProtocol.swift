import Foundation
import Network

// MARK: - DLNAProtocol

/// DLNA协议实现
@available(macOS 11.0, *)
class DLNAProtocol: Protocol {
    
    // MARK: - Basic Properties
    
    /// 协议的唯一标识符
    var identifier: String = "com.macast.protocol.dlna"
    
    /// 协议名称
    var name: String = "DLNA"
    
    /// 协议描述
    var description: String = "数字生活网络联盟协议实现"
    
    /// 协议版本
    var version: String = "1.5"
    
    /// 协议是否已启用
    var isEnabled: Bool = true
    
    // MARK: - Protocol State
    
    /// 协议是否已启动
    var isRunning: Bool = false
    
    // MARK: - Private Properties
    
    /// SSDP服务器
    private var ssdpServer: SSDPServer?
    
    /// DLNA服务管理器
    private var dlnaServiceManager: DLNAServiceManager?
    
    /// HTTP服务器
    private var httpServer: HTTPServer?
    
    // MARK: - Initialization
    
    required init() {
        // 初始化SSDP服务器
        ssdpServer = SSDPServer()
        
        // 初始化DLNA服务管理器
        dlnaServiceManager = DLNAServiceManager.shared
        
        // 初始化HTTP服务器
        httpServer = HTTPServer()
    }
    
    // MARK: - Lifecycle Methods
    
    /// 启动协议
    func start() throws {
        if !isRunning {
            // 启动HTTP服务器
            httpServer?.start()
            
            // 获取HTTP服务器的URL并设置给SSDP服务器
            if let serverURL = httpServer?.getServerURL() {
                ssdpServer?.serverURL = serverURL
                
                // 启动SSDP服务器
                ssdpServer?.start()
                
                // 更新运行状态
                isRunning = true
                
                // 调用协议启动完成方法
                protocolDidStart()
            } else {
                // HTTP服务器启动失败，清理资源
                httpServer?.stop()
                throw ProtocolError.protocolStartFailed
            }
        }
    }
    
    /// 停止协议
    func stop() throws {
        if isRunning {
            // 停止SSDP服务器
            ssdpServer?.stop()
            
            // 停止HTTP服务器
            httpServer?.stop()
            
            // 更新运行状态
            isRunning = false
            
            // 调用协议停止完成方法
            protocolDidStop()
        }
    }
    
    /// 处理请求
    func handleRequest(_ request: NetworkRequest) -> NetworkResponse? {
        // 这里可以处理DLNA特定的请求
        // 目前HTTP服务器已经处理了DLNA请求，所以这里可以返回nil
        return nil
    }
}
