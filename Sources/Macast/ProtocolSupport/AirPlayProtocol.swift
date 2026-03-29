import Foundation
import Network

// MARK: - AirPlayProtocol

/// AirPlay协议实现
@available(macOS 11.0, *)
class AirPlayProtocol: Protocol {
    
    // MARK: - Basic Properties
    
    /// 协议的唯一标识符
    var identifier: String = "com.macast.protocol.airplay"
    
    /// 协议名称
    var name: String = "AirPlay"
    
    /// 协议描述
    var description: String = "AirPlay媒体渲染协议实现"
    
    /// 协议版本
    var version: String = "2.0"
    
    /// 协议是否已启用
    var isEnabled: Bool = true
    
    // MARK: - Protocol State
    
    /// 协议是否已启动
    var isRunning: Bool = false
    
    // MARK: - Private Properties
    
    /// AirPlay服务器
    private var airplayServer: AirPlayServer?
    
    /// HTTP服务器
    private var httpServer: HTTPServer?
    
    // MARK: - Initialization
    
    required init() {
        // 初始化HTTP服务器
        httpServer = HTTPServer()
        
        // 初始化AirPlay服务器
        airplayServer = AirPlayServer()
    }
    
    // MARK: - Lifecycle Methods
    
    /// 启动协议
    func start() throws {
        if !isRunning {
            // 启动HTTP服务器
            httpServer?.start()
            
            // 获取HTTP服务器的URL并设置给AirPlay服务器
            if let serverURL = httpServer?.getServerURL() {
                airplayServer?.serverURL = serverURL
                
                // 启动AirPlay服务器
                try airplayServer?.start()
                
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
            // 停止AirPlay服务器
            airplayServer?.stop()
            
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
        // 处理AirPlay特定的请求
        return airplayServer?.handleRequest(request)
    }
    
    // MARK: - Helper Methods
    
    /// 协议启动完成回调
    private func protocolDidStart() {
        print("AirPlay协议已启动")
    }
    
    /// 协议停止完成回调
    private func protocolDidStop() {
        print("AirPlay协议已停止")
    }
}
