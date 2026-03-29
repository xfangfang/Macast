import Foundation
import UserNotifications

// MARK: - NotificationManager

/// 通知管理器，处理应用程序的通知功能
class NotificationManager {
    
    // MARK: - Singleton
    
    /// 单例实例
    static let shared = NotificationManager()
    
    // MARK: - Properties
    
    /// 是否启用通知
    var notificationsEnabled: Bool
    
    /// 服务状态通知是否启用
    var serviceStatusNotificationsEnabled: Bool
    
    /// 媒体播放通知是否启用
    var mediaPlaybackNotificationsEnabled: Bool
    
    // MARK: - Initialization
    
    private init() {
        // 加载设置
        let userDefaults = UserDefaults.standard
        notificationsEnabled = userDefaults.bool(forKey: "notificationsEnabled")
        serviceStatusNotificationsEnabled = userDefaults.bool(forKey: "serviceStatusNotificationsEnabled")
        mediaPlaybackNotificationsEnabled = userDefaults.bool(forKey: "mediaPlaybackNotificationsEnabled")
        
        if NSClassFromString("XCTestCase") == nil {
            requestNotificationPermission()
        }
    }
    
    // MARK: - Permission Management
    
    /// 请求通知权限
    func requestNotificationPermission() {
        guard Bundle.main.bundleIdentifier != nil else {
            print("警告: 无法获取 Bundle Identifier，可能是因为在调试环境或 SwiftPM 下运行。跳过请求通知权限。")
            return
        }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, error in
            if let error = error {
                print("请求通知权限失败: \(error)")
                return
            }
            
            // 更新通知启用状态
            self?.notificationsEnabled = granted
            self?.saveSettings()
        }
    }
    
    /// 检查通知权限
    func checkNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            completion(settings.authorizationStatus == .authorized)
        }
    }
    
    // MARK: - Notification Sending
    
    /// 发送服务启动通知
    func sendServiceStartedNotification() {
        guard notificationsEnabled && serviceStatusNotificationsEnabled else {
            return
        }
        
        sendNotification(title: "Macast服务已启动", body: "您可以开始使用DLNA、AirPlay和Chromecast进行媒体投放")
    }
    
    /// 发送服务停止通知
    func sendServiceStoppedNotification() {
        guard notificationsEnabled && serviceStatusNotificationsEnabled else {
            return
        }
        
        sendNotification(title: "Macast服务已停止", body: "媒体投放功能已关闭")
    }
    
    /// 发送媒体播放开始通知
    func sendMediaPlaybackStartedNotification(mediaTitle: String?) {
        guard notificationsEnabled && mediaPlaybackNotificationsEnabled else {
            return
        }
        
        let body = mediaTitle != nil ? "正在播放: \(mediaTitle!)" : "媒体播放已开始"
        sendNotification(title: "媒体播放开始", body: body)
    }
    
    /// 发送媒体播放暂停通知
    func sendMediaPlaybackPausedNotification(mediaTitle: String?) {
        guard notificationsEnabled && mediaPlaybackNotificationsEnabled else {
            return
        }
        
        let body = mediaTitle != nil ? "已暂停: \(mediaTitle!)" : "媒体播放已暂停"
        sendNotification(title: "媒体播放暂停", body: body)
    }
    
    /// 发送媒体播放停止通知
    func sendMediaPlaybackStoppedNotification() {
        guard notificationsEnabled && mediaPlaybackNotificationsEnabled else {
            return
        }
        
        sendNotification(title: "媒体播放结束", body: "媒体播放已停止")
    }
    
    /// 发送媒体播放错误通知
    func sendMediaPlaybackErrorNotification(errorMessage: String) {
        guard notificationsEnabled && mediaPlaybackNotificationsEnabled else {
            return
        }
        
        sendNotification(title: "媒体播放错误", body: errorMessage)
    }
    
    /// 发送插件安装完成通知
    func sendPluginInstalledNotification(pluginName: String) {
        guard notificationsEnabled else {
            return
        }
        
        sendNotification(title: "插件安装完成", body: "\(pluginName)插件已成功安装")
    }
    
    /// 发送插件更新完成通知
    func sendPluginUpdatedNotification(pluginName: String) {
        guard notificationsEnabled else {
            return
        }
        
        sendNotification(title: "插件更新完成", body: "\(pluginName)插件已成功更新")
    }
    
    // MARK: - Private Methods
    
    /// 发送通知
    private func sendNotification(title: String, body: String) {
        // 创建通知内容
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        // 创建通知请求
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        // 发送通知
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("发送通知失败: \(error)")
            }
        }
    }
    
    // MARK: - Settings Management
    
    /// 保存设置
    func saveSettings() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(notificationsEnabled, forKey: "notificationsEnabled")
        userDefaults.set(serviceStatusNotificationsEnabled, forKey: "serviceStatusNotificationsEnabled")
        userDefaults.set(mediaPlaybackNotificationsEnabled, forKey: "mediaPlaybackNotificationsEnabled")
    }
    
    /// 重置设置为默认值
    func resetToDefaults() {
        notificationsEnabled = true
        serviceStatusNotificationsEnabled = true
        mediaPlaybackNotificationsEnabled = true
        saveSettings()
    }
}

// MARK: - NotificationCategory

/// 通知类别枚举
enum NotificationCategory {
    case serviceStatus
    case mediaPlayback
    case pluginManagement
}
