import Foundation

// DLNA服务协议
enum DLNAServiceType: String {
    case connectionManager = "ConnectionManager"
    case avTransport = "AVTransport"
    case renderingControl = "RenderingControl"
}

// DLNA服务协议
protocol DLNAServiceProtocol {
    // 服务类型
    var serviceType: DLNAServiceType { get }
    
    // 服务ID
    var serviceId: String { get }
    
    // 服务描述文件URL
    var scpdURL: String { get }
    
    // 控制URL
    var controlURL: String { get }
    
    // 事件订阅URL
    var eventSubURL: String { get }
    
    // 处理SOAP动作请求
    func handleSOAPAction(action: String, parameters: [String: String]) -> Data
    
    // 获取服务描述XML
    func getServiceDescription() -> String
}

// DLNA服务基类
class DLNAServiceBase: DLNAServiceProtocol {
    // MARK: - Properties
    
    var serviceType: DLNAServiceType
    var serviceId: String
    var scpdURL: String
    var controlURL: String
    var eventSubURL: String
    
    // MARK: - Initialization
    
    init(serviceType: DLNAServiceType) {
        self.serviceType = serviceType
        self.serviceId = "urn:upnp-org:serviceId:\(serviceType.rawValue)"
        self.scpdURL = "dlna/\(serviceType.rawValue).xml"
        self.controlURL = "\(serviceType.rawValue)/action"
        self.eventSubURL = "\(serviceType.rawValue)/event"
    }
    
    // MARK: - DLNAServiceProtocol Methods
    
    // 处理SOAP动作请求（子类需要重写）
    func handleSOAPAction(action: String, parameters: [String: String]) -> Data {
        // 默认实现，返回空响应
        let response = "<?xml version=\"1.0\" encoding=\"utf-8\"?><s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\" s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\"><s:Body></s:Body></s:Envelope>"
        return response.data(using: .utf8) ?? Data()
    }
    
    // 获取服务描述XML（子类需要重写）
    func getServiceDescription() -> String {
        // 默认实现，返回基本的服务描述XML
        return "<?xml version=\"1.0\" encoding=\"utf-8\"?><scpd xmlns=\"urn:schemas-upnp-org:service-1-0\"><specVersion><major>1</major><minor>0</minor></specVersion></scpd>"
    }
    
    // MARK: - Helper Methods
    
    // 构建SOAP响应
    func buildSOAPResponse(action: String, responseParameters: [String: String]) -> Data {
        let actionName = action.components(separatedBy: "#").last ?? ""
        let responseAction = actionName.replacingOccurrences(of: "", with: "Response")
        
        var responseBody = "<u:\(responseAction) xmlns:u=\"urn:schemas-upnp-org:service:\(serviceType.rawValue):1\">"
        
        for (key, value) in responseParameters {
            responseBody += "<\(key)>\(value)</\(key)>"
        }
        
        responseBody += "</u:\(responseAction)>"
        
        let response = "<?xml version=\"1.0\" encoding=\"utf-8\"?><s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\" s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\"><s:Body>\(responseBody)</s:Body></s:Envelope>"
        
        return response.data(using: .utf8) ?? Data()
    }
}
