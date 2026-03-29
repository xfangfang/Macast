import Foundation

// DLNA服务管理器
class DLNAServiceManager {
    
    // MARK: - Properties
    
    // 单例实例
    static let shared = DLNAServiceManager()
    
    // 所有DLNA服务
    private var services: [DLNAServiceType: DLNAServiceProtocol]
    
    private struct EventSubscription {
        let sid: String
        let serviceType: DLNAServiceType
        let callbackURLs: [URL]
        var expiration: Date
        var sequenceNumber: Int
    }
    
    private let subscriptionQueue = DispatchQueue(label: "com.macast.dlna.eventing.subscriptions")
    private var subscriptionsBySID: [String: EventSubscription] = [:]
    
    // MARK: - Initialization
    
    private init() {
        // 初始化所有DLNA服务
        services = [
            .connectionManager: ConnectionManagerService(),
            .avTransport: AVTransportService(),
            .renderingControl: RenderingControlService()
        ]
    }
    
    // MARK: - Public Methods
    
    // 获取服务
    func getService(type: DLNAServiceType) -> DLNAServiceProtocol? {
        return services[type]
    }
    
    // 获取服务描述XML
    func getServiceDescription(for path: String) -> String? {
        // 提取服务类型
        if let serviceType = extractServiceType(from: path) {
            return services[serviceType]?.getServiceDescription()
        }
        return nil
    }
    
    // 处理服务控制请求
    func handleServiceRequest(path: String, body: Data) -> Data {
        // 提取服务类型
        guard let serviceType = extractServiceType(from: path) else {
            return buildErrorResponse(code: 404, message: "Not Found")
        }
        
        // 获取对应的服务
        guard let service = services[serviceType] else {
            return buildErrorResponse(code: 404, message: "Service Not Found")
        }
        
        let bodyString = String(data: body, encoding: .utf8) ?? ""
        guard let (action, parameters) = parseSOAPRequest(bodyString, soapActionHeader: nil, serviceType: serviceType) else {
            return buildSOAPErrorResponse(code: "402", description: "Invalid SOAP Request")
        }
        
        // 处理SOAP动作
        return service.handleSOAPAction(action: action, parameters: parameters)
    }

    func handleServiceRequest(serviceName: String, headers: [String: String], body: Data) -> Data {
        guard let serviceType = DLNAServiceType(rawValue: serviceName) else {
            return buildErrorResponse(code: 404, message: "Not Found")
        }

        guard let service = services[serviceType] else {
            return buildErrorResponse(code: 404, message: "Service Not Found")
        }

        let soapActionHeader = extractSOAPActionHeader(from: headers)
        let bodyString = String(data: body, encoding: .utf8) ?? ""

        guard let (action, parameters) = parseSOAPRequest(bodyString, soapActionHeader: soapActionHeader, serviceType: serviceType) else {
            return buildSOAPErrorResponse(code: "402", description: "Invalid SOAP Request")
        }

        return service.handleSOAPAction(action: action, parameters: parameters)
    }
    
    func handleEventRequest(method: String, serviceName: String, headers: [String: String]) -> (statusCode: Int, headers: [String: String]) {
        removeExpiredSubscriptions()
        
        guard let serviceType = DLNAServiceType(rawValue: serviceName) else {
            return (404, [:])
        }
        
        switch method.uppercased() {
        case "SUBSCRIBE":
            if let sid = headerValue(headers, name: "SID") {
                return renewSubscription(sid: sid, headers: headers)
            }
            return createSubscription(serviceType: serviceType, headers: headers)
        case "UNSUBSCRIBE":
            guard let sid = headerValue(headers, name: "SID") else {
                return (400, [:])
            }
            return removeSubscription(sid: sid)
        default:
            return (405, [:])
        }
    }
    
    // MARK: - Private Methods
    
    // 从路径中提取服务类型
    private func extractServiceType(from path: String) -> DLNAServiceType? {
        if path.contains("ConnectionManager") { return .connectionManager }
        if path.contains("AVTransport") { return .avTransport }
        if path.contains("RenderingControl") { return .renderingControl }
        return nil
    }
    
    // 解析SOAP请求
    private func parseSOAPRequest(_ request: String, soapActionHeader: String?, serviceType: DLNAServiceType) -> (String, [String: String])? {
        let normalizedSOAPAction = soapActionHeader?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))

        let action: String
        if let normalizedSOAPAction, normalizedSOAPAction.contains("#") {
            action = normalizedSOAPAction
        } else {
            guard let actionName = extractActionNameFromBody(request) else { return nil }
            action = "urn:schemas-upnp-org:service:\(serviceType.rawValue):1#\(actionName)"
        }

        let actionName = action.components(separatedBy: "#").last ?? ""
        let parameters = extractParametersFromBody(request, actionName: actionName)
        return (action, parameters)
    }

    private func extractSOAPActionHeader(from headers: [String: String]) -> String? {
        for (key, value) in headers where key.caseInsensitiveCompare("SOAPACTION") == .orderedSame {
            return value
        }
        return nil
    }
    
    private func headerValue(_ headers: [String: String], name: String) -> String? {
        for (key, value) in headers where key.caseInsensitiveCompare(name) == .orderedSame {
            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }
    
    private func parseCallbackURLs(from callbackHeader: String) -> [URL] {
        let pattern = "<([^>]+)>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        let range = NSRange(location: 0, length: callbackHeader.utf16.count)
        let matches = regex.matches(in: callbackHeader, options: [], range: range)
        
        var urls: [URL] = []
        for match in matches {
            guard let urlRange = Range(match.range(at: 1), in: callbackHeader) else { continue }
            let urlString = String(callbackHeader[urlRange])
            guard let url = URL(string: urlString), url.scheme?.lowercased() == "http" else { continue }
            urls.append(url)
        }
        return urls
    }
    
    private func parseTimeoutSeconds(from timeoutHeader: String?) -> TimeInterval {
        guard let timeoutHeader else { return 1800 }
        let normalized = timeoutHeader.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.lowercased().contains("infinite") { return 1800 }
        let parts = normalized.split(separator: "-")
        guard parts.count == 2, let seconds = TimeInterval(parts[1]) else { return 1800 }
        return max(1, min(seconds, 7200))
    }
    
    private func removeExpiredSubscriptions() {
        subscriptionQueue.sync {
            let now = Date()
            subscriptionsBySID = subscriptionsBySID.filter { $0.value.expiration > now }
        }
    }
    
    private func createSubscription(serviceType: DLNAServiceType, headers: [String: String]) -> (statusCode: Int, headers: [String: String]) {
        guard let callbackHeader = headerValue(headers, name: "CALLBACK") else {
            return (412, [:])
        }
        let callbackURLs = parseCallbackURLs(from: callbackHeader)
        if callbackURLs.isEmpty {
            return (412, [:])
        }
        
        let timeoutSeconds = parseTimeoutSeconds(from: headerValue(headers, name: "TIMEOUT"))
        let sid = "uuid:\(UUID().uuidString)"
        let expiration = Date().addingTimeInterval(timeoutSeconds)
        
        let subscription = EventSubscription(
            sid: sid,
            serviceType: serviceType,
            callbackURLs: callbackURLs,
            expiration: expiration,
            sequenceNumber: 0
        )
        
        subscriptionQueue.sync {
            subscriptionsBySID[sid] = subscription
        }
        
        sendInitialNotify(for: subscription)
        
        return (200, [
            "SID": sid,
            "TIMEOUT": "Second-\(Int(timeoutSeconds))"
        ])
    }
    
    private func renewSubscription(sid: String, headers: [String: String]) -> (statusCode: Int, headers: [String: String]) {
        let timeoutSeconds = parseTimeoutSeconds(from: headerValue(headers, name: "TIMEOUT"))
        let updated: EventSubscription? = subscriptionQueue.sync {
            guard var subscription = subscriptionsBySID[sid] else { return nil }
            subscription.expiration = Date().addingTimeInterval(timeoutSeconds)
            subscriptionsBySID[sid] = subscription
            return subscription
        }
        
        guard updated != nil else {
            return (412, [:])
        }
        
        return (200, [
            "SID": sid,
            "TIMEOUT": "Second-\(Int(timeoutSeconds))"
        ])
    }
    
    private func removeSubscription(sid: String) -> (statusCode: Int, headers: [String: String]) {
        let removed: Bool = subscriptionQueue.sync {
            subscriptionsBySID.removeValue(forKey: sid) != nil
        }
        
        return removed ? (200, [:]) : (412, [:])
    }
    
    private func sendInitialNotify(for subscription: EventSubscription) {
        let (contentType, bodyData) = buildInitialEventBody(for: subscription.serviceType)
        for callbackURL in subscription.callbackURLs {
            var request = URLRequest(url: callbackURL)
            request.httpMethod = "NOTIFY"
            request.httpBody = bodyData
            request.setValue("upnp:event", forHTTPHeaderField: "NT")
            request.setValue("upnp:propchange", forHTTPHeaderField: "NTS")
            request.setValue(subscription.sid, forHTTPHeaderField: "SID")
            request.setValue(String(subscription.sequenceNumber), forHTTPHeaderField: "SEQ")
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
            request.setValue(String(bodyData.count), forHTTPHeaderField: "Content-Length")
            
            URLSession.shared.dataTask(with: request).resume()
        }
    }
    
    private func buildInitialEventBody(for serviceType: DLNAServiceType) -> (contentType: String, body: Data) {
        let lastChange = buildLastChange(for: serviceType)
        let xml =
            "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
            + "<e:propertyset xmlns:e=\"urn:schemas-upnp-org:event-1-0\">"
            + "<e:property><LastChange>\(escapeForXML(lastChange))</LastChange></e:property>"
            + "</e:propertyset>"
        let data = xml.data(using: .utf8) ?? Data()
        return ("text/xml; charset=\"utf-8\"", data)
    }
    
    private func buildLastChange(for serviceType: DLNAServiceType) -> String {
        switch serviceType {
        case .avTransport:
            let state = (services[.avTransport] as? AVTransportService)?.currentTransportState ?? "STOPPED"
            let status = (services[.avTransport] as? AVTransportService)?.currentTransportStatus ?? "OK"
            return "<Event xmlns=\"urn:schemas-upnp-org:metadata-1-0/AVT/\"><InstanceID val=\"0\"><TransportState val=\"\(state)\"/><TransportStatus val=\"\(status)\"/></InstanceID></Event>"
        case .renderingControl:
            let volume = (services[.renderingControl] as? RenderingControlService)?.volume["Master"] ?? 50
            let muted = (services[.renderingControl] as? RenderingControlService)?.mute["Master"] ?? false
            return "<Event xmlns=\"urn:schemas-upnp-org:metadata-1-0/RCS/\"><InstanceID val=\"0\"><Volume channel=\"Master\" val=\"\(volume)\"/><Mute channel=\"Master\" val=\"\(muted ? 1 : 0)\"/></InstanceID></Event>"
        case .connectionManager:
            return "<Event xmlns=\"urn:schemas-upnp-org:metadata-1-0/CM/\"><InstanceID val=\"0\"/></Event>"
        }
    }
    
    private func escapeForXML(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private func extractActionNameFromBody(_ xml: String) -> String? {
        let bodyPattern = "<(?:\\w+:)?Body[^>]*>([\\s\\S]*?)</(?:\\w+:)?Body>"
        guard let bodyRegex = try? NSRegularExpression(pattern: bodyPattern, options: .caseInsensitive),
              let bodyMatch = bodyRegex.firstMatch(in: xml, options: [], range: NSRange(location: 0, length: xml.utf16.count)),
              let bodyRange = Range(bodyMatch.range(at: 1), in: xml)
        else { return nil }

        let bodyContent = String(xml[bodyRange])
        let tagPattern = "<\\s*([A-Za-z0-9_]+:)?([A-Za-z0-9_]+)\\b"
        guard let tagRegex = try? NSRegularExpression(pattern: tagPattern, options: .caseInsensitive),
              let tagMatch = tagRegex.firstMatch(in: bodyContent, options: [], range: NSRange(location: 0, length: bodyContent.utf16.count)),
              let nameRange = Range(tagMatch.range(at: 2), in: bodyContent)
        else { return nil }

        return String(bodyContent[nameRange])
    }

    private func extractParametersFromBody(_ xml: String, actionName: String) -> [String: String] {
        let actionPattern = "<(?:\\w+:)?\(NSRegularExpression.escapedPattern(for: actionName))\\b[^>]*>([\\s\\S]*?)</(?:\\w+:)?\(NSRegularExpression.escapedPattern(for: actionName))>"
        guard let actionRegex = try? NSRegularExpression(pattern: actionPattern, options: [.caseInsensitive]),
              let actionMatch = actionRegex.firstMatch(in: xml, options: [], range: NSRange(location: 0, length: xml.utf16.count)),
              let actionBodyRange = Range(actionMatch.range(at: 1), in: xml)
        else { return [:] }

        let actionBody = String(xml[actionBodyRange])
        var parameters: [String: String] = [:]

        let paramPattern = "<([A-Za-z0-9_]+)>([\\s\\S]*?)</\\1>"
        let paramRegex = try? NSRegularExpression(pattern: paramPattern, options: [.caseInsensitive])
        let matches = paramRegex?.matches(in: actionBody, options: [], range: NSRange(location: 0, length: actionBody.utf16.count)) ?? []

        for match in matches {
            guard let nameRange = Range(match.range(at: 1), in: actionBody),
                  let valueRange = Range(match.range(at: 2), in: actionBody)
            else { continue }

            let name = String(actionBody[nameRange])
            let value = String(actionBody[valueRange])
            parameters[name] = value
        }

        return parameters
    }
    
    // 构建SOAP错误响应
    private func buildSOAPErrorResponse(code: String, description: String) -> Data {
        let response = "<?xml version=\"1.0\" encoding=\"utf-8\"?><s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\" s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">"
            + "<s:Body><s:Fault><faultcode>s:Client</faultcode><faultstring>UPnPError</faultstring>"
            + "<detail><UPnPError xmlns=\"urn:schemas-upnp-org:control-1-0\"><errorCode>\(code)</errorCode><errorDescription>\(description)</errorDescription></UPnPError></detail></s:Fault></s:Body></s:Envelope>"
        
        return response.data(using: .utf8) ?? Data()
    }
    
    // 构建HTTP错误响应
    private func buildErrorResponse(code: Int, message: String) -> Data {
        let statusMessage = getStatusMessage(for: code)
        let response = "HTTP/1.1 \(code) \(statusMessage)\r\n"
            + "Content-Type: text/plain\r\n"
            + "Content-Length: \(message.count)\r\n"
            + "\r\n"
            + message
        
        return response.data(using: .utf8) ?? Data()
    }
    
    // 获取状态消息
    private func getStatusMessage(for statusCode: Int) -> String {
        switch statusCode {
        case 200: return "OK"
        case 400: return "Bad Request"
        case 404: return "Not Found"
        case 500: return "Internal Server Error"
        default: return "Unknown Error"
        }
    }
}
