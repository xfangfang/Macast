import Foundation

// ConnectionManager服务类
class ConnectionManagerService: DLNAServiceBase {
    
    // MARK: - Properties
    
    // 支持的协议信息
    private let sourceProtocolInfo = "http-get:*:video/mpeg:*;http-get:*:video/mp4:*;http-get:*:video/quicktime:*;http-get:*:video/x-ms-wmv:*;http-get:*:audio/mpeg:*;http-get:*:audio/x-ms-wma:*;http-get:*:image/jpeg:*;http-get:*:image/png:*"
    private let sinkProtocolInfo = ""
    private let currentConnectionIDs = "0"
    
    // MARK: - Initialization
    
    init() {
        super.init(serviceType: .connectionManager)
    }
    
    // MARK: - DLNAServiceProtocol Methods
    
    // 处理SOAP动作请求
    override func handleSOAPAction(action: String, parameters: [String: String]) -> Data {
        switch action {
        case "urn:schemas-upnp-org:service:ConnectionManager:1#GetProtocolInfo":
            return handleGetProtocolInfo(parameters: parameters)
        case "urn:schemas-upnp-org:service:ConnectionManager:1#GetCurrentConnectionIDs":
            return handleGetCurrentConnectionIDs(parameters: parameters)
        case "urn:schemas-upnp-org:service:ConnectionManager:1#GetCurrentConnectionInfo":
            return handleGetCurrentConnectionInfo(parameters: parameters)
        case "urn:schemas-upnp-org:service:ConnectionManager:1#GetPeerConnectionManager":
            return handleGetPeerConnectionManager(parameters: parameters)
        case "urn:schemas-upnp-org:service:ConnectionManager:1#GetPeerConnectionID":
            return handleGetPeerConnectionID(parameters: parameters)
        case "urn:schemas-upnp-org:service:ConnectionManager:1#GetDirection":
            return handleGetDirection(parameters: parameters)
        case "urn:schemas-upnp-org:service:ConnectionManager:1#GetStatus":
            return handleGetStatus(parameters: parameters)
        default:
            return super.handleSOAPAction(action: action, parameters: parameters)
        }
    }
    
    // 获取服务描述XML
    override func getServiceDescription() -> String {
        return "<?xml version=\"1.0\" encoding=\"utf-8\"?><scpd xmlns=\"urn:schemas-upnp-org:service-1-0\">"
            + "<specVersion><major>1</major><minor>0</minor></specVersion>"
            + "<actionList>"
            + "<action><name>GetCurrentConnectionIDs</name><argumentList><argument><name>ConnectionIDs</name><direction>out</direction><relatedStateVariable>CurrentConnectionIDs</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>GetCurrentConnectionInfo</name><argumentList><argument><name>ConnectionID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_ConnectionID</relatedStateVariable></argument><argument><name>RcsID</name><direction>out</direction><relatedStateVariable>A_ARG_TYPE_RcsID</relatedStateVariable></argument><argument><name>AVTransportID</name><direction>out</direction><relatedStateVariable>A_ARG_TYPE_AVTransportID</relatedStateVariable></argument><argument><name>ProtocolInfo</name><direction>out</direction><relatedStateVariable>A_ARG_TYPE_ProtocolInfo</relatedStateVariable></argument><argument><name>PeerConnectionManager</name><direction>out</direction><relatedStateVariable>A_ARG_TYPE_ConnectionManager</relatedStateVariable></argument><argument><name>PeerConnectionID</name><direction>out</direction><relatedStateVariable>A_ARG_TYPE_ConnectionID</relatedStateVariable></argument><argument><name>Direction</name><direction>out</direction><relatedStateVariable>A_ARG_TYPE_Direction</relatedStateVariable></argument><argument><name>Status</name><direction>out</direction><relatedStateVariable>A_ARG_TYPE_ConnectionStatus</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>GetDirection</name><argumentList><argument><name>ConnectionID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_ConnectionID</relatedStateVariable></argument><argument><name>Direction</name><direction>out</direction><relatedStateVariable>A_ARG_TYPE_Direction</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>GetPeerConnectionID</name><argumentList><argument><name>ConnectionID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_ConnectionID</relatedStateVariable></argument><argument><name>PeerConnectionManager</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_ConnectionManager</relatedStateVariable></argument><argument><name>PeerConnectionID</name><direction>out</direction><relatedStateVariable>A_ARG_TYPE_ConnectionID</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>GetPeerConnectionManager</name><argumentList><argument><name>ConnectionID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_ConnectionID</relatedStateVariable></argument><argument><name>PeerConnectionManager</name><direction>out</direction><relatedStateVariable>A_ARG_TYPE_ConnectionManager</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>GetProtocolInfo</name><argumentList><argument><name>Source</name><direction>out</direction><relatedStateVariable>SourceProtocolInfo</relatedStateVariable></argument><argument><name>Sink</name><direction>out</direction><relatedStateVariable>SinkProtocolInfo</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>GetStatus</name><argumentList><argument><name>ConnectionID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_ConnectionID</relatedStateVariable></argument><argument><name>Status</name><direction>out</direction><relatedStateVariable>A_ARG_TYPE_ConnectionStatus</relatedStateVariable></argument></argumentList></action>"
            + "</actionList>"
            + "<serviceStateTable>"
            + "<stateVariable sendEvents=\"yes\"><name>SourceProtocolInfo</name><dataType>string</dataType><defaultValue>\(sourceProtocolInfo)</defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>SinkProtocolInfo</name><dataType>string</dataType><defaultValue>\(sinkProtocolInfo)</defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>CurrentConnectionIDs</name><dataType>string</dataType><defaultValue>\(currentConnectionIDs)</defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"no\"><name>A_ARG_TYPE_ConnectionStatus</name><dataType>string</dataType><allowedValueList><allowedValue>OK</allowedValue><allowedValue>ContentFormatMismatch</allowedValue><allowedValue>InsufficientBandwidth</allowedValue><allowedValue>UnreliableChannel</allowedValue><allowedValue>Unknown</allowedValue></allowedValueList></stateVariable>"
            + "<stateVariable sendEvents=\"no\"><name>A_ARG_TYPE_ConnectionID</name><dataType>i4</dataType></stateVariable>"
            + "<stateVariable sendEvents=\"no\"><name>A_ARG_TYPE_ConnectionManager</name><dataType>string</dataType></stateVariable>"
            + "<stateVariable sendEvents=\"no\"><name>A_ARG_TYPE_Direction</name><dataType>string</dataType><allowedValueList><allowedValue>Input</allowedValue><allowedValue>Output</allowedValue></allowedValueList></stateVariable>"
            + "<stateVariable sendEvents=\"no\"><name>A_ARG_TYPE_ProtocolInfo</name><dataType>string</dataType></stateVariable>"
            + "<stateVariable sendEvents=\"no\"><name>A_ARG_TYPE_RcsID</name><dataType>i4</dataType></stateVariable>"
            + "<stateVariable sendEvents=\"no\"><name>A_ARG_TYPE_AVTransportID</name><dataType>i4</dataType></stateVariable>"
            + "</serviceStateTable>"
            + "</scpd>"
    }
    
    // MARK: - Action Handlers
    
    // 处理GetProtocolInfo动作
    private func handleGetProtocolInfo(parameters: [String: String]) -> Data {
        return buildSOAPResponse(action: "GetProtocolInfo", responseParameters: [
            "Source": sourceProtocolInfo,
            "Sink": sinkProtocolInfo
        ])
    }
    
    // 处理GetCurrentConnectionIDs动作
    private func handleGetCurrentConnectionIDs(parameters: [String: String]) -> Data {
        return buildSOAPResponse(action: "GetCurrentConnectionIDs", responseParameters: [
            "ConnectionIDs": currentConnectionIDs
        ])
    }
    
    // 处理GetCurrentConnectionInfo动作
    private func handleGetCurrentConnectionInfo(parameters: [String: String]) -> Data {
        // 如果提供了ConnectionID参数，检查是否有效
        if let connectionID = parameters["ConnectionID"], connectionID != "0" {
            // 无效的连接ID，返回错误响应
            return buildSOAPErrorResponse(code: "706", description: "Invalid Connection Reference")
        }
        
        return buildSOAPResponse(action: "GetCurrentConnectionInfo", responseParameters: [
            "RcsID": "0",
            "AVTransportID": "0",
            "ProtocolInfo": sourceProtocolInfo,
            "PeerConnectionManager": "",
            "PeerConnectionID": "-1",
            "Direction": "Output",
            "Status": "OK"
        ])
    }
    
    // 处理GetPeerConnectionManager动作
    private func handleGetPeerConnectionManager(parameters: [String: String]) -> Data {
        // 如果提供了ConnectionID参数，检查是否有效
        if let connectionID = parameters["ConnectionID"], connectionID != "0" {
            // 无效的连接ID，返回错误响应
            return buildSOAPErrorResponse(code: "706", description: "Invalid Connection Reference")
        }
        
        return buildSOAPResponse(action: "GetPeerConnectionManager", responseParameters: [
            "PeerConnectionManager": ""
        ])
    }
    
    // 处理GetPeerConnectionID动作
    private func handleGetPeerConnectionID(parameters: [String: String]) -> Data {
        // 如果提供了ConnectionID参数，检查是否有效
        if let connectionID = parameters["ConnectionID"], connectionID != "0" {
            // 无效的连接ID，返回错误响应
            return buildSOAPErrorResponse(code: "706", description: "Invalid Connection Reference")
        }
        
        return buildSOAPResponse(action: "GetPeerConnectionID", responseParameters: [
            "PeerConnectionID": "-1"
        ])
    }
    
    // 处理GetDirection动作
    private func handleGetDirection(parameters: [String: String]) -> Data {
        // 如果提供了ConnectionID参数，检查是否有效
        if let connectionID = parameters["ConnectionID"], connectionID != "0" {
            // 无效的连接ID，返回错误响应
            return buildSOAPErrorResponse(code: "706", description: "Invalid Connection Reference")
        }
        
        return buildSOAPResponse(action: "GetDirection", responseParameters: [
            "Direction": "Output"
        ])
    }
    
    // 处理GetStatus动作
    private func handleGetStatus(parameters: [String: String]) -> Data {
        // 如果提供了ConnectionID参数，检查是否有效
        if let connectionID = parameters["ConnectionID"], connectionID != "0" {
            // 无效的连接ID，返回错误响应
            return buildSOAPErrorResponse(code: "706", description: "Invalid Connection Reference")
        }
        
        return buildSOAPResponse(action: "GetStatus", responseParameters: [
            "Status": "OK"
        ])
    }
    
    // MARK: - Helper Methods
    
    // 构建SOAP错误响应
    private func buildSOAPErrorResponse(code: String, description: String) -> Data {
        let response = "<?xml version=\"1.0\" encoding=\"utf-8\"?><s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\" s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">"
            + "<s:Body><s:Fault><faultcode>s:Client</faultcode><faultstring>UPnPError</faultstring>"
            + "<detail><UPnPError xmlns=\"urn:schemas-upnp-org:control-1-0\"><errorCode>\(code)</errorCode><errorDescription>\(description)</errorDescription></UPnPError></detail></s:Fault></s:Body></s:Envelope>"
        
        return response.data(using: .utf8) ?? Data()
    }
}
