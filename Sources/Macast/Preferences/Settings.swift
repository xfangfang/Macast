import Foundation
import AppKit

// MARK: - Settings

/// 应用程序设置
class Settings {
    
    // MARK: - Singleton
    
    /// 单例实例
    static let shared = Settings()
    
    // MARK: - Properties
    
    // 常规设置
    var automaticallyStartAtLogin: Bool = false
    var showMenuBarIcon: Bool = true
    var defaultRenderer: String = "MPV"
    var appearanceMode: String = "system" // system, light, dark
    
    // 网络设置
    var httpPort: Int = 8008
    var ssdpEnabled: Bool = true
    var ssdpTTL: Int = 4
    var networkInterface: String = "all"
    
    // 播放设置
    var defaultVolume: Int = 50
    var bufferSize: Int = 2048
    var playbackQuality: String = "auto"
    
    // 高级设置
    var logLevel: String = "info"
    var debugMode: Bool = false
    var enableHTTPS: Bool = false
    
    // 插件设置
    var pluginsEnabled: Bool = true
    var pluginAutoUpdate: Bool = false
    
    // MARK: - Initialization
    
    private init() {
        // 加载设置
        loadSettings()
        
        // 应用外观模式
        applyAppearanceMode()
    }
    
    // MARK: - Settings Management
    
    /// 加载设置
    func loadSettings() {
        let userDefaults = UserDefaults.standard
        
        // 加载常规设置
        automaticallyStartAtLogin = userDefaults.bool(forKey: "automaticallyStartAtLogin")
        showMenuBarIcon = userDefaults.bool(forKey: "showMenuBarIcon")
        defaultRenderer = userDefaults.string(forKey: "defaultRenderer") ?? "MPV"
        appearanceMode = userDefaults.string(forKey: "appearanceMode") ?? "system"
        
        // 加载网络设置
        httpPort = userDefaults.integer(forKey: "httpPort")
        if httpPort == 0 {
            httpPort = 8008
        }
        ssdpEnabled = userDefaults.bool(forKey: "ssdpEnabled")
        ssdpTTL = userDefaults.integer(forKey: "ssdpTTL")
        if ssdpTTL == 0 {
            ssdpTTL = 4
        }
        networkInterface = userDefaults.string(forKey: "networkInterface") ?? "all"
        
        // 加载播放设置
        defaultVolume = userDefaults.integer(forKey: "defaultVolume")
        if defaultVolume == 0 {
            defaultVolume = 50
        }
        bufferSize = userDefaults.integer(forKey: "bufferSize")
        if bufferSize == 0 {
            bufferSize = 2048
        }
        playbackQuality = userDefaults.string(forKey: "playbackQuality") ?? "auto"
        
        // 加载高级设置
        logLevel = userDefaults.string(forKey: "logLevel") ?? "info"
        debugMode = userDefaults.bool(forKey: "debugMode")
        enableHTTPS = userDefaults.bool(forKey: "enableHTTPS")
        
        // 加载插件设置
        pluginsEnabled = userDefaults.bool(forKey: "pluginsEnabled")
        pluginAutoUpdate = userDefaults.bool(forKey: "pluginAutoUpdate")
    }
    
    /// 应用外观模式
    func applyAppearanceMode() {
        let appearance: NSAppearance?
        
        switch appearanceMode {
        case "light":
            appearance = NSAppearance(named: .aqua)
        case "dark":
            appearance = NSAppearance(named: .darkAqua)
        default:
            appearance = nil // 跟随系统设置
        }
        
        DispatchQueue.main.async {
            NSApp.appearance = appearance
        }
    }
    
    /// 保存设置
    func saveSettings() {
        let userDefaults = UserDefaults.standard
        
        // 保存常规设置
        userDefaults.set(automaticallyStartAtLogin, forKey: "automaticallyStartAtLogin")
        userDefaults.set(showMenuBarIcon, forKey: "showMenuBarIcon")
        userDefaults.set(defaultRenderer, forKey: "defaultRenderer")
        userDefaults.set(appearanceMode, forKey: "appearanceMode")
        
        // 保存网络设置
        userDefaults.set(httpPort, forKey: "httpPort")
        userDefaults.set(ssdpEnabled, forKey: "ssdpEnabled")
        userDefaults.set(ssdpTTL, forKey: "ssdpTTL")
        userDefaults.set(networkInterface, forKey: "networkInterface")
        
        // 保存播放设置
        userDefaults.set(defaultVolume, forKey: "defaultVolume")
        userDefaults.set(bufferSize, forKey: "bufferSize")
        userDefaults.set(playbackQuality, forKey: "playbackQuality")
        
        // 保存高级设置
        userDefaults.set(logLevel, forKey: "logLevel")
        userDefaults.set(debugMode, forKey: "debugMode")
        userDefaults.set(enableHTTPS, forKey: "enableHTTPS")
        
        // 保存插件设置
        userDefaults.set(pluginsEnabled, forKey: "pluginsEnabled")
        userDefaults.set(pluginAutoUpdate, forKey: "pluginAutoUpdate")
        
        // 同步设置
        userDefaults.synchronize()
        
        // 通知设置已变更
        NotificationCenter.default.post(name: .settingsChanged, object: nil)
    }
    
    /// 重置设置为默认值
    func resetToDefaults() {
        // 重置常规设置
        automaticallyStartAtLogin = false
        showMenuBarIcon = true
        defaultRenderer = "MPV"
        appearanceMode = "system"
        
        // 重置网络设置
        httpPort = 8008
        ssdpEnabled = true
        ssdpTTL = 4
        networkInterface = "all"
        
        // 重置播放设置
        defaultVolume = 50
        bufferSize = 2048
        playbackQuality = "auto"
        
        // 重置高级设置
        logLevel = "info"
        debugMode = false
        enableHTTPS = false
        
        // 重置插件设置
        pluginsEnabled = true
        pluginAutoUpdate = false
        
        // 保存默认设置
        saveSettings()
    }
    
    // MARK: - Validation
    
    /// 验证HTTP端口
    func validateHTTPPort(_ port: Int) -> Bool {
        return port >= 1024 && port <= 65535
    }
    
    /// 验证SSDP TTL
    func validateSSDTTL(_ ttl: Int) -> Bool {
        return ttl >= 1 && ttl <= 255
    }
    
    /// 验证音量
    func validateVolume(_ volume: Int) -> Bool {
        return volume >= 0 && volume <= 100
    }
    
    /// 验证缓冲区大小
    func validateBufferSize(_ size: Int) -> Bool {
        return size >= 512 && size <= 65536
    }
}

// MARK: - Notification Name Extension

extension Notification.Name {
    static let settingsChanged = Notification.Name("com.macast.settingsChanged")
}
