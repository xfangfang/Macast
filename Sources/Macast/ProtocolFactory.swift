import Foundation

protocol ProtocolFactory {
    func createDLNAProtocol() -> DLNAProtocol
    func createProtocolManager() -> ProtocolManager
}

class DefaultProtocolFactory: ProtocolFactory {
    func createDLNAProtocol() -> DLNAProtocol {
        return DLNAProtocol()
    }
    
    func createProtocolManager() -> ProtocolManager {
        return ProtocolManager.shared
    }
}
