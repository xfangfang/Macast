import Foundation

// 网络工具类
enum NetworkUtils {
    // 获取所有网络接口的IP地址
    static func getIPAddresses() -> [String] {
        var addresses: [String] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        
        // 获取所有网络接口
        guard getifaddrs(&ifaddr) == 0 else {
            return []
        }
        
        var interface = ifaddr
        while interface != nil {
            guard let addressPointer = interface?.pointee.ifa_addr else {
                interface = interface?.pointee.ifa_next
                continue
            }
            
            // 检查是否是IPv4地址
            if addressPointer.pointee.sa_family == UInt8(AF_INET) {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                let result = getnameinfo(addressPointer, socklen_t(addressPointer.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                
                if result == 0 {
                    let ip = String(cString: hostname)
                    addresses.append(ip)
                }
            }
            
            interface = interface?.pointee.ifa_next
        }
        
        freeifaddrs(ifaddr)
        
        return addresses
    }
    
    // 获取第一个网络接口的IP地址
    static func getFirstIPAddress() -> String? {
        return getIPAddresses().first
    }
}
