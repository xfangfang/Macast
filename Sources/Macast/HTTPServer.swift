import Foundation
import Network

// HTTP服务器类
class HTTPServer {
    
    // MARK: - Properties
    
    private var listener: NWListener?
    private var serverURL: URL?
    private var deviceDescriptionXML: String?
    private var serviceHandlers: [String: (Data) -> Data] = [:]
    
    // 响应缓存
    private var responseCache: [String: Data] = [:]

    private let deviceUUID = UUID().uuidString
    private let serialNumber = UUID().uuidString
    
    // MARK: - Initialization
    
    init() {
        // 延迟生成设备描述XML，直到服务器URL可用
    }
    
    // MARK: - Public Methods
    
    // 启动HTTP服务器
    func start(port: UInt16 = 8008) {
        do {
            // 创建TCP监听器
            listener = try NWListener(using: .tcp, on: NWEndpoint.Port(integerLiteral: port))
            
            // 设置状态更新处理程序
            listener?.stateUpdateHandler = { [weak self] state in
                self?.handleListenerState(state)
                // 当监听器准备就绪时，生成设备描述XML
                if state == .ready, let port = self?.listener?.port?.rawValue {
                    let ip = self?.resolveLANIPAddress() ?? "127.0.0.1"
                    self?.serverURL = URL(string: "http://\(ip):\(port)")
                    self?.generateDeviceDescriptionXML()
                }
            }
            
            // 设置新连接处理程序
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection)
            }
            
            // 启动监听器
            listener?.start(queue: .global())
        } catch {
            print("无法创建HTTP监听器: \(error)")
            return
        }
        
        // 初始设置服务器URL
        let ip = resolveLANIPAddress() ?? "127.0.0.1"
        serverURL = URL(string: "http://\(ip):\(port)")
        generateDeviceDescriptionXML()
    }
    
    // 停止HTTP服务器
    func stop() {
        listener?.cancel()
        listener = nil
        print("HTTP服务器已停止")
    }
    
    // 获取服务器URL
    func getServerURL() -> URL? {
        return serverURL
    }
    
    // MARK: - Private Methods
    
    // 处理监听器状态变化
    private func handleListenerState(_ state: NWListener.State) {
        switch state {
        case .ready:
            print("HTTP服务器已启动，监听端口: \(listener?.port?.rawValue ?? 0)")
        case .waiting(let error):
            print("HTTP服务器等待中: \(error)")
        case .failed(let error):
            print("HTTP服务器失败: \(error)")
            listener?.cancel()
        default:
            break
        }
    }
    
    // 处理新的连接
    private func handleNewConnection(_ connection: NWConnection) {
        // 设置连接状态更新处理程序
        connection.stateUpdateHandler = { [weak self] state in
            self?.handleConnectionState(connection, state: state)
        }
        
        // 开始接收数据
        receiveData(connection)
        
        // 启动连接
        connection.start(queue: .global())
    }
    
    // 处理连接状态变化
    private func handleConnectionState(_ connection: NWConnection, state: NWConnection.State) {
        switch state {
        case .failed(let error):
            print("连接失败: \(error)")
            connection.cancel()
        case .cancelled:
            print("连接已取消")
        default:
            break
        }
    }
    
    // 接收数据
    private func receiveData(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024 * 1024) { [weak self] data, context, isComplete, error in
            if let error = error {
                print("接收数据失败: \(error)")
                connection.cancel()
                return
            }
            
            if let data = data {
                // 处理HTTP请求
                self?.handleHTTPRequest(connection, data: data)
            }
            
            if !isComplete {
                // 继续接收数据
                self?.receiveData(connection)
            }
        }
    }
    
    // 处理HTTP请求
    private func handleHTTPRequest(_ connection: NWConnection, data: Data) {
        // 解析HTTP请求
        guard var requestString = String(data: data, encoding: .utf8) else {
            sendErrorResponse(connection, statusCode: 400, message: "Bad Request")
            return
        }
        
        // 安全处理：清理HTTP请求
        let securityManager = SecurityManager.shared
        requestString = securityManager.sanitizeHTTPRequest(requestString)
        
        guard let request = parseHTTPRequest(requestString) else {
            sendErrorResponse(connection, statusCode: 400, message: "Bad Request")
            return
        }
        
        // 根据请求方法和路径处理请求
        switch (request.method, request.path) {
        case ("GET", "/description.xml"):
            handleDeviceDescriptionRequest(connection)
        case ("GET", let path) where path.hasPrefix("/dlna/") && path.hasSuffix(".xml"):
            handleDLNAServiceDescriptionRequest(connection, path: path)
        case ("POST", let path) where path.hasSuffix("/action"):
            handleDLNAServiceActionRequest(connection, path: path, headers: request.headers, body: request.body)
        case ("SUBSCRIBE", let path) where path.hasSuffix("/event"):
            handleDLNAServiceEventRequest(connection, method: request.method, path: path, headers: request.headers)
        case ("UNSUBSCRIBE", let path) where path.hasSuffix("/event"):
            handleDLNAServiceEventRequest(connection, method: request.method, path: path, headers: request.headers)
        case ("GET", let path) where path.hasPrefix("/service/"):
            handleServiceDescriptionRequest(connection, path: path)
        case ("POST", let path) where path.hasPrefix("/service/"):
            handleServiceActionRequest(connection, path: path, body: request.body)
        default:
            sendErrorResponse(connection, statusCode: 404, message: "Not Found")
        }
    }
    
    // 处理设备描述请求
    private func handleDeviceDescriptionRequest(_ connection: NWConnection) {
        guard let deviceDescriptionXML = deviceDescriptionXML else {
            sendErrorResponse(connection, statusCode: 500, message: "Internal Server Error")
            return
        }
        
        // 检查缓存
        let cacheKey = "/description.xml"
        if let cachedResponse = responseCache[cacheKey] {
            connection.send(content: cachedResponse, completion: .contentProcessed { error in
                if let error = error {
                    print("发送缓存响应失败: \(error)")
                }
                connection.cancel()
            })
            return
        }
        
        sendResponse(connection, statusCode: 200, headers: [
            "Content-Type": "application/xml"
        ], body: deviceDescriptionXML.data(using: .utf8), cacheKey: cacheKey)
    }
    
    // 处理服务描述请求
    private func handleServiceDescriptionRequest(_ connection: NWConnection, path: String) {
        // 检查缓存
        if let cachedResponse = responseCache[path] {
            connection.send(content: cachedResponse, completion: .contentProcessed { error in
                if let error = error {
                    print("发送缓存响应失败: \(error)")
                }
                connection.cancel()
            })
            return
        }
        
        // 使用DLNAServiceManager获取服务描述
        if let serviceDescription = DLNAServiceManager.shared.getServiceDescription(for: path) {
            sendResponse(connection, statusCode: 200, headers: [
                "Content-Type": "application/xml"
            ], body: serviceDescription.data(using: .utf8), cacheKey: path)
        } else {
            sendErrorResponse(connection, statusCode: 404, message: "Service Description Not Found")
        }
    }
    
    // 处理服务操作请求
    private func handleServiceActionRequest(_ connection: NWConnection, path: String, body: Data) {
        // 使用DLNAServiceManager处理服务请求
        let response = DLNAServiceManager.shared.handleServiceRequest(path: path, body: body)
        
        sendResponse(connection, statusCode: 200, headers: [
            "Content-Type": "text/xml; charset=utf-8"
        ], body: response)
    }

    private func handleDLNAServiceDescriptionRequest(_ connection: NWConnection, path: String) {
        if let cachedResponse = responseCache[path] {
            connection.send(content: cachedResponse, completion: .contentProcessed { error in
                if let error = error {
                    print("发送缓存响应失败: \(error)")
                }
                connection.cancel()
            })
            return
        }

        if let staticData = loadStaticDLNAXMLData(path: path) {
            sendResponse(connection, statusCode: 200, headers: [
                "Content-Type": "application/xml"
            ], body: staticData, cacheKey: path)
        } else if let serviceDescription = DLNAServiceManager.shared.getServiceDescription(for: path) {
            sendResponse(connection, statusCode: 200, headers: [
                "Content-Type": "application/xml"
            ], body: serviceDescription.data(using: .utf8), cacheKey: path)
        } else {
            sendErrorResponse(connection, statusCode: 404, message: "Service Description Not Found")
        }
    }

    private func handleDLNAServiceActionRequest(_ connection: NWConnection, path: String, headers: [String: String], body: Data) {
        guard let serviceName = extractServiceName(fromActionPath: path) else {
            sendErrorResponse(connection, statusCode: 404, message: "Not Found")
            return
        }

        let response = DLNAServiceManager.shared.handleServiceRequest(serviceName: serviceName, headers: headers, body: body)

        sendResponse(connection, statusCode: 200, headers: [
            "Content-Type": "text/xml; charset=utf-8"
        ], body: response)
    }
    
    private func handleDLNAServiceEventRequest(_ connection: NWConnection, method: String, path: String, headers: [String: String]) {
        guard let serviceName = extractServiceName(fromEventPath: path) else {
            sendErrorResponse(connection, statusCode: 404, message: "Not Found")
            return
        }
        
        let result = DLNAServiceManager.shared.handleEventRequest(method: method, serviceName: serviceName, headers: headers)
        if result.statusCode == 200 {
            var responseHeaders: [String: String] = [:]
            for (k, v) in result.headers {
                responseHeaders[k] = v
            }
            sendResponse(connection, statusCode: 200, headers: responseHeaders, body: nil)
        } else {
            sendErrorResponse(connection, statusCode: result.statusCode, message: "Event Subscription Error")
        }
    }

    private func extractServiceName(fromActionPath path: String) -> String? {
        let parts = path.split(separator: "/").map(String.init)
        guard parts.count >= 2, parts.last == "action" else { return nil }
        return parts.first
    }
    
    private func extractServiceName(fromEventPath path: String) -> String? {
        let parts = path.split(separator: "/").map(String.init)
        guard parts.count >= 2, parts.last == "event" else { return nil }
        return parts.first
    }

    private func resolveLANIPAddress() -> String? {
        NetworkUtils.getIPAddresses().first(where: { ip in
            !ip.hasPrefix("127.") && !ip.hasPrefix("169.254.")
        })
    }

    private func loadStaticDLNAXMLData(path: String) -> Data? {
        guard path.hasPrefix("/dlna/") else { return nil }
        let fileName = String(path.split(separator: "/").last ?? "")
        let allowed: Set<String> = [
            "AVTransport.xml",
            "RenderingControl.xml",
            "ConnectionManager.xml"
        ]
        guard allowed.contains(fileName) else { return nil }

        let stem = fileName.replacingOccurrences(of: ".xml", with: "")
        if let moduleURL = Bundle.module.url(forResource: stem, withExtension: "xml"),
           let data = try? Data(contentsOf: moduleURL) {
            return data
        }

        if let bundledURL = Bundle.main.resourceURL?.appendingPathComponent(fileName),
           let data = try? Data(contentsOf: bundledURL) {
            return data
        }

        let cwdURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repoURL = cwdURL.appendingPathComponent("Resources").appendingPathComponent(fileName)
        return try? Data(contentsOf: repoURL)
    }
    
    // 发送HTTP响应
    private func sendResponse(_ connection: NWConnection, statusCode: Int, headers: [String: String], body: Data?, cacheKey: String? = nil) {
        // 构建状态行
        let statusMessage = getStatusMessage(for: statusCode)
        var response = "HTTP/1.1 \(statusCode) \(statusMessage)\r\n"
        
        // 添加头部
        for (key, value) in headers {
            response += "\(key): \(value)\r\n"
        }
        
        // 添加Content-Length头部
        if let body = body {
            response += "Content-Length: \(body.count)\r\n"
        }
        
        // 添加空行分隔头部和主体
        response += "\r\n"
        
        // 构建完整响应数据
        var fullResponseData = response.data(using: .utf8)!
        if let body = body {
            fullResponseData.append(body)
        }
        
        // 缓存响应
        if let cacheKey = cacheKey {
            responseCache[cacheKey] = fullResponseData
        }
        
        // 发送完整响应
        connection.send(content: fullResponseData, completion: .contentProcessed { error in
            if let error = error {
                print("发送响应失败: \(error)")
            }
            // 关闭连接
            connection.cancel()
        })
    }
    
    // 发送错误响应
    private func sendErrorResponse(_ connection: NWConnection, statusCode: Int, message: String) {
        // 构建错误页面
        let errorHTML = "<html><head><title>\(statusCode) \(message)</title></head><body><h1>\(statusCode) \(message)</h1><p>The requested resource was not found.</p></body></html>"
        
        sendResponse(connection, statusCode: statusCode, headers: [
            "Content-Type": "text/html"
        ], body: errorHTML.data(using: .utf8))
    }
    
    // 解析HTTP请求
    private func parseHTTPRequest(_ requestString: String) -> HTTPRequest? {
        let lines = requestString.split(separator: "\r\n", omittingEmptySubsequences: false)
        guard lines.count > 0 else {
            return nil
        }
        
        // 解析请求行
        let requestLine = lines[0].split(separator: " ", maxSplits: 2)
        guard requestLine.count == 3 else {
            return nil
        }
        
        let method = String(requestLine[0])
        let path = String(requestLine[1])
        let version = String(requestLine[2])
        
        // 解析头部
        var headers: [String: String] = [:]
        var body: Data? = nil
        var isHeaderSection = true
        
        for i in 1..<lines.count {
            let line = lines[i]
            
            if line.isEmpty {
                // 头部结束，开始主体
                isHeaderSection = false
                continue
            }
            
            if isHeaderSection {
                // 解析头部行
                if let colonIndex = line.firstIndex(of: ":") {
                    let key = String(line[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                    let value = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                    headers[key] = value
                }
            } else {
                // 收集主体内容
                if let lineData = line.data(using: .utf8) {
                    if body == nil {
                        body = Data()
                    }
                    body?.append(lineData)
                    // 添加回车换行（因为split会移除它们）
                    body?.append("\r\n".data(using: .utf8)!)
                }
            }
        }
        
        // 如果有主体，移除最后的回车换行
        if var bodyData = body, bodyData.count > 2 {
            bodyData = bodyData.subdata(in: 0..<bodyData.count - 2)
            body = bodyData
        }
        
        return HTTPRequest(method: method, path: path, version: version, headers: headers, body: body ?? Data())
    }
    
    // 生成设备描述XML
    private func generateDeviceDescriptionXML() {
        deviceDescriptionXML =
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
            + "<root xmlns:dlna=\"urn:schemas-dlna-org:device-1-0\" xmlns=\"urn:schemas-upnp-org:device-1-0\">"
            + "<specVersion><major>1</major><minor>0</minor></specVersion>"
            + "<device>"
            + "<deviceType>urn:schemas-upnp-org:device:MediaRenderer:1</deviceType>"
            + "<UDN>uuid:\(deviceUUID)</UDN>"
            + "<friendlyName>Macast</friendlyName>"
            + "<manufacturer>Macast Team</manufacturer>"
            + "<manufacturerURL>https://github.com/xfangfang/Macast</manufacturerURL>"
            + "<modelDescription>Macast Media Renderer</modelDescription>"
            + "<modelName>Macast</modelName>"
            + "<modelNumber>1.0</modelNumber>"
            + "<modelURL>https://github.com/xfangfang/Macast</modelURL>"
            + "<serialNumber>\(serialNumber)</serialNumber>"
            + "<dlna:X_DLNADOC xmlns:dlna=\"urn:schemas-dlna-org:device-1-0\">DMR-1.50</dlna:X_DLNADOC>"
            + "<serviceList>"
            + "<service>"
            + "<serviceType>urn:schemas-upnp-org:service:AVTransport:1</serviceType>"
            + "<serviceId>urn:upnp-org:serviceId:AVTransport</serviceId>"
            + "<controlURL>AVTransport/action</controlURL>"
            + "<eventSubURL>AVTransport/event</eventSubURL>"
            + "<SCPDURL>dlna/AVTransport.xml</SCPDURL>"
            + "</service>"
            + "<service>"
            + "<serviceType>urn:schemas-upnp-org:service:RenderingControl:1</serviceType>"
            + "<serviceId>urn:upnp-org:serviceId:RenderingControl</serviceId>"
            + "<controlURL>RenderingControl/action</controlURL>"
            + "<eventSubURL>RenderingControl/event</eventSubURL>"
            + "<SCPDURL>dlna/RenderingControl.xml</SCPDURL>"
            + "</service>"
            + "<service>"
            + "<serviceType>urn:schemas-upnp-org:service:ConnectionManager:1</serviceType>"
            + "<serviceId>urn:upnp-org:serviceId:ConnectionManager</serviceId>"
            + "<controlURL>ConnectionManager/action</controlURL>"
            + "<eventSubURL>ConnectionManager/event</eventSubURL>"
            + "<SCPDURL>dlna/ConnectionManager.xml</SCPDURL>"
            + "</service>"
            + "</serviceList>"
            + "</device>"
            + "</root>"
        
        print("设备描述XML已生成")
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

// HTTP请求结构体
struct HTTPRequest {
    let method: String
    let path: String
    let version: String
    let headers: [String: String]
    let body: Data
}
