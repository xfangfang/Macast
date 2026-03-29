import Foundation
import CommonCrypto

class SecurityManager {
    static let shared = SecurityManager()
    
    // 用于CSRF保护的密钥
    private let csrfKey = "MacastCSRFKey"
    
    // 用于加密的密钥（在实际应用中应该更安全地生成和存储）
    private let encryptionKey = Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16])
    
    private init() {}
    
    // MARK: - UUID Generation
    
    func generateUUID() -> String {
        return UUID().uuidString.uppercased()
    }
    
    // MARK: - URL Validation
    
    func validateURL(_ url: URL) -> Bool {
        // 检查URL方案
        guard let scheme = url.scheme?.lowercased(), (scheme == "http" || scheme == "https") else {
            return false
        }
        
        // 检查主机
        guard let host = url.host else {
            return false
        }
        
        // 允许本地网络地址
        let allowedHosts = ["localhost", "127.0.0.1"]
        if allowedHosts.contains(host) {
            return true
        }
        
        // 允许私有IP地址（192.168.x.x, 10.x.x.x, 172.16.x.x-172.31.x.x）
        let privateIPPatterns = [
            "^192\\.168\\.\\d+\\.\\d+$",
            "^10\\.\\d+\\.\\d+\\.\\d+$",
            "^172\\.(1[6-9]|2\\d|3[01])\\.\\d+\\.\\d+$",
            "^fc00::/7.*",  // IPv6 唯一本地地址
            "^fe80::/10.*"   // IPv6 链路本地地址
        ]
        
        for pattern in privateIPPatterns {
            if host.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Input Sanitization
    
    func sanitizeInput(_ input: String) -> String {
        // 移除HTML/XML标签
        var sanitized = input.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        // 移除特殊字符（允许基本的文本字符）
        sanitized = sanitized.replacingOccurrences(of: "[^a-zA-Z0-9\\s\\.,!?'\\-]", with: "", options: .regularExpression)
        
        return sanitized
    }
    
    // MARK: - HTTP Request Sanitization
    
    func sanitizeHTTPRequest(_ request: String) -> String {
        // 移除潜在的危险字符和序列
        var sanitized = request
        
        // 移除可能的SQL注入攻击
        let sqlPatterns = [
            "'" + "OR" + " 1=1",
            "'" + "--",
            ";",
            "DROP TABLE",
            "INSERT INTO",
            "UPDATE.*SET.*='"
        ]
        
        for pattern in sqlPatterns {
            sanitized = sanitized.replacingOccurrences(of: pattern, with: "", options: .caseInsensitive)
        }
        
        return sanitized
    }
    
    // MARK: - CSRF Protection
    
    func generateCSRFToken() -> String {
        let token = UUID().uuidString
        UserDefaults.standard.set(token, forKey: csrfKey)
        UserDefaults.standard.synchronize()
        return token
    }
    
    func validateCSRFToken(_ token: String) -> Bool {
        guard let storedToken = UserDefaults.standard.string(forKey: csrfKey) else {
            return false
        }
        return token == storedToken
    }
    
    // MARK: - Encryption/Decryption
    
    func encrypt(_ data: Data) -> Data? {
        guard let key = generateEncryptionKey() else { return nil }
        
        let encryptedDataSize = kCCBlockSizeAES128 + data.count
        var encryptedData = Data(count: encryptedDataSize)
        var numBytesEncrypted: size_t = 0
        
        let status = key.withUnsafeBytes { keyBytes in
            data.withUnsafeBytes { dataBytes in
                encryptedData.withUnsafeMutableBytes { encryptedBytes in
                    CCCrypt(
                        CCOperation(kCCEncrypt),
                        CCAlgorithm(kCCAlgorithmAES128),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyBytes.baseAddress,
                        kCCKeySizeAES128,
                        nil,
                        dataBytes.baseAddress,
                        data.count,
                        encryptedBytes.baseAddress,
                        encryptedDataSize,
                        &numBytesEncrypted
                    )
                }
            }
        }
        
        if status == kCCSuccess {
            encryptedData.removeSubrange(numBytesEncrypted..<encryptedData.count)
            return encryptedData
        }
        
        return nil
    }
    
    func decrypt(_ data: Data) -> Data? {
        guard let key = generateEncryptionKey() else { return nil }
        
        let decryptedDataSize = data.count
        var decryptedData = Data(count: decryptedDataSize)
        var numBytesDecrypted: size_t = 0
        
        let status = key.withUnsafeBytes { keyBytes in
            data.withUnsafeBytes { dataBytes in
                decryptedData.withUnsafeMutableBytes { decryptedBytes in
                    CCCrypt(
                        CCOperation(kCCDecrypt),
                        CCAlgorithm(kCCAlgorithmAES128),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyBytes.baseAddress,
                        kCCKeySizeAES128,
                        nil,
                        dataBytes.baseAddress,
                        data.count,
                        decryptedBytes.baseAddress,
                        decryptedDataSize,
                        &numBytesDecrypted
                    )
                }
            }
        }
        
        if status == kCCSuccess {
            decryptedData.removeSubrange(numBytesDecrypted..<decryptedData.count)
            return decryptedData
        }
        
        return nil
    }
    
    // MARK: - Private Helper Methods
    
    private func generateEncryptionKey() -> Data? {
        // 在实际应用中，应该使用更安全的方式生成和存储密钥
        // 这里只是一个简单的示例
        return encryptionKey
    }
}
