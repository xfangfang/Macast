import Foundation

enum Logging {
    static func info(_ message: String) {
        print("[INFO] \(Date()): \(message)")
    }
    
    static func debug(_ message: String) {
        #if DEBUG
        print("[DEBUG] \(Date()): \(message)")
        #endif
    }
    
    static func error(_ message: String) {
        print("[ERROR] \(Date()): \(message)")
    }
}
