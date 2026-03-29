import Foundation
import AppKit

// MARK: - QuickTimeRenderer

/// QuickTime Player渲染器实现
class QuickTimeRenderer: DLNARendererProtocol {
    
    // MARK: - MacastPlugin Properties
    
    /// 插件的唯一标识符
    let identifier: String = "com.macast.renderer.quicktime"
    
    /// 插件名称
    var name: String { get { return friendlyName } set { friendlyName = newValue } }
    
    /// 插件版本
    let version: String = "1.0.0"
    
    /// 插件描述
    let description: String = "QuickTime Player渲染器插件"
    
    /// 插件作者
    let author: String = "Macast开发团队"
    
    /// 插件主页
    let homepage: URL? = URL(string: "https://github.com/macast-dev/macast-quicktime-renderer")
    
    /// 插件是否已启用
    var isEnabled: Bool = true
    
    /// 插件是否已加载
    var isLoaded: Bool = false
    
    /// 插件依赖的其他插件
    let dependencies: [PluginDependency] = []
    
    // MARK: - DLNARendererProtocol Properties
    
    /// 渲染器的友好名称
    var friendlyName: String = "QuickTime渲染器"
    
    /// 渲染器的UDN (Unique Device Name)
    let udn: String = "uuid:quicktime-renderer-" + UUID().uuidString
    
    /// 渲染器的型号名称
    let modelName: String = "QuickTime Player"
    
    /// 渲染器的制造商
    let manufacturer: String = "Apple Inc."
    
    /// 渲染器的当前状态
    var playbackState: DLNAPlaybackState = .stopped
    
    /// 当前播放的媒体信息
    var currentMediaInfo: DLNAMediaInfo?
    
    /// 音量信息
    var volumeInfo: DLNAVolumeInfo
    
    /// 支持的播放速率
    let supportedPlaybackRates: [String] = ["1.0"]
    
    /// 支持的媒体格式
    let supportedMediaFormats: [String] = [
        "video/quicktime",
        "video/mp4",
        "video/x-m4v",
        "audio/mp3",
        "audio/mp4",
        "audio/x-m4a",
        "image/jpeg",
        "image/png",
        "image/gif"
    ]
    
    // MARK: - Private Properties
    
    /// AppleScript控制器
    private let appleScriptController: QuickTimeAppleScriptController
    
    /// 事件监听器
    private var eventListeners: [DLNARendererEventListener] = []
    
    /// 通知管理器
    private let notificationManager: NotificationManager
    
    // MARK: - Initialization
    
    required init() {
        // 初始化AppleScript控制器
        appleScriptController = QuickTimeAppleScriptController()
        
        // 初始化通知管理器
        notificationManager = NotificationManager.shared
        
        // 初始化音量信息
        volumeInfo = DLNAVolumeInfo(
            volume: 100,
            maxVolume: 100,
            muted: false
        )
    }
    
    // MARK: - Playback Control Methods
    
    /// 加载媒体
    /// - Parameter mediaURL: 媒体URL
    /// - Parameter position: 开始播放的位置（秒）
    func loadMedia(mediaURL: URL, position: Double) throws {
        // 更新播放状态
        playbackState = .transitioning
        notifyPlaybackStateChanged()
        
        // 打开QuickTime Player应用
        _ = try appleScriptController.runAppleScript("tell application \"QuickTime Player\" to activate")
        
        // 关闭所有现有窗口
        _ = try appleScriptController.runAppleScript("tell application \"QuickTime Player\" to close every document")
        
        // 打开媒体文件
        let script = "tell application \"QuickTime Player\" to open \"mediaURL.path)\""
        _ = try appleScriptController.runAppleScript(script)
        
        // 等待媒体加载
        usleep(500000) // 等待0.5秒
        
        // 设置初始播放位置
        if position > 0 {
            try seekTo(position: position)
        }
        
        // 更新媒体信息
        updateCurrentMediaInfo()
        
        // 发送媒体播放开始通知
        notificationManager.sendMediaPlaybackStartedNotification(mediaTitle: currentMediaInfo?.title)
        
        // 开始播放
        try play()
    }
    
    /// 播放
    func play() throws {
        // 发送播放命令
        _ = try appleScriptController.runAppleScript("tell application \"QuickTime Player\" to play every document")
        
        // 更新播放状态
        playbackState = .playing
        notifyPlaybackStateChanged()
    }
    
    /// 暂停
    func pause() throws {
        // 发送暂停命令
        _ = try appleScriptController.runAppleScript("tell application \"QuickTime Player\" to pause every document")
        
        // 更新播放状态
        playbackState = .paused
        notifyPlaybackStateChanged()
        
        // 发送媒体播放暂停通知
        notificationManager.sendMediaPlaybackPausedNotification(mediaTitle: currentMediaInfo?.title)
    }
    
    /// 停止
    func stop() throws {
        // 发送停止命令
        _ = try appleScriptController.runAppleScript("tell application \"QuickTime Player\" to stop every document")
        
        // 更新播放状态
        playbackState = .stopped
        notifyPlaybackStateChanged()
        
        // 发送媒体播放停止通知
        notificationManager.sendMediaPlaybackStoppedNotification()
        
        // 清除媒体信息
        currentMediaInfo = nil
        notifyMediaInfoChanged()
    }
    
    /// 快进
    /// - Parameter seconds: 快进的秒数
    func seekForward(seconds: Double) throws {
        // 获取当前位置
        let currentPosition = getCurrentPosition()
        
        // 跳转到新位置
        try seekTo(position: currentPosition + seconds)
    }
    
    /// 快退
    /// - Parameter seconds: 快退的秒数
    func seekBackward(seconds: Double) throws {
        // 获取当前位置
        let currentPosition = getCurrentPosition()
        
        // 跳转到新位置
        try seekTo(position: max(0, currentPosition - seconds))
    }
    
    /// 跳转到指定位置
    /// - Parameter position: 位置（秒）
    func seekTo(position: Double) throws {
        // 发送跳转命令
        let script = "tell application \"QuickTime Player\" to set current time of every document to \(position)"
        _ = try appleScriptController.runAppleScript(script)
    }
    
    /// 设置播放速率
    /// - Parameter rate: 播放速率 (1为正常速度, 2为两倍速, 0.5为半速)
    func setPlaybackRate(rate: Double) throws {
        // QuickTime Player通常不支持播放速率调整
        // 这里只支持正常速度
        if rate != 1.0 {
            throw QuickTimeRendererError.unsupportedPlaybackRate
        }
    }
    
    /// 获取当前播放位置
    /// - Returns: 当前播放位置（秒）
    func getCurrentPosition() -> Double {
        // 发送获取当前位置命令
        if let result = try? appleScriptController.runAppleScript("tell application \"QuickTime Player\" to get current time of first document") {
            return Double(result) ?? 0.0
        }
        
        return 0.0
    }
    
    // MARK: - Volume Control Methods
    
    /// 设置音量
    /// - Parameter volume: 音量值（0-100）
    func setVolume(volume: Int) throws {
        // 确保音量在有效范围内
        let validVolume = max(0, min(100, volume))
        
        // 发送设置音量命令
        let script = "tell application \"QuickTime Player\" to set audio volume of every document to \(validVolume)"
        _ = try appleScriptController.runAppleScript(script)
        
        // 更新音量信息
        volumeInfo.volume = validVolume
        volumeInfo.muted = validVolume == 0
        notifyVolumeChanged()
    }
    
    /// 增加音量
    /// - Parameter delta: 增加的音量值（1-100）
    func increaseVolume(delta: Int) throws {
        // 计算新音量
        let newVolume = min(100, volumeInfo.volume + delta)
        
        // 设置新音量
        try setVolume(volume: newVolume)
    }
    
    /// 减少音量
    /// - Parameter delta: 减少的音量值（1-100）
    func decreaseVolume(delta: Int) throws {
        // 计算新音量
        let newVolume = max(0, volumeInfo.volume - delta)
        
        // 设置新音量
        try setVolume(volume: newVolume)
    }
    
    /// 设置静音状态
    /// - Parameter muted: 静音状态
    func setMuted(muted: Bool) throws {
        if muted {
            // 保存当前音量
            let currentVolume = volumeInfo.volume
            if currentVolume > 0 {
                // 设置音量为0
                try setVolume(volume: 0)
                
                // 更新静音状态
                volumeInfo.muted = true
                notifyVolumeChanged()
            }
        } else {
            // 取消静音（恢复之前的音量）
            if volumeInfo.muted {
                // 设置音量为100（默认值）
                try setVolume(volume: 100)
                
                // 更新静音状态
                volumeInfo.muted = false
                notifyVolumeChanged()
            }
        }
    }
    
    // MARK: - Transport Control Methods
    
    /// 获取当前传输状态
    func getTransportInfo() -> DLNATransportInfo {
        return DLNATransportInfo(
            transportState: playbackState,
            transportStatus: "OK",
            playSpeed: "1.0"
        )
    }
    
    /// 获取当前媒体信息
    func getMediaInfo() -> DLNAMediaInfo? {
        return currentMediaInfo
    }
    
    /// 获取当前位置信息
    func getPositionInfo() -> DLNAPositionInfo {
        let currentPosition = getCurrentPosition()
        let duration = currentMediaInfo?.duration ?? 0.0
        
        // 格式化时间
        let formatTime = { (seconds: Double) -> String in
            let h = Int(seconds / 3600)
            let m = Int((seconds / 60).truncatingRemainder(dividingBy: 60))
            let s = Int(seconds.truncatingRemainder(dividingBy: 60))
            return String(format: "%02d:%02d:%02d", h, m, s)
        }
        
        return DLNAPositionInfo(
            currentPosition: currentPosition,
            currentTime: formatTime(currentPosition),
            totalTime: formatTime(duration),
            trackNumber: 1,
            mediaURL: currentMediaInfo?.mediaURL
        )
    }
    
    /// 获取设备功能
    func getDeviceCapabilities() -> DLNADeviceCapabilities {
        return DLNADeviceCapabilities(
            playbackRateList: supportedPlaybackRates,
            recQualityModes: [],
            transportPlayStates: ["PLAYING", "PAUSED_PLAYBACK", "STOPPED", "TRANSITIONING"],
            transportRecStates: []
        )
    }
    
    /// 获取播放速率列表
    func getPlaybackRateList() -> [String] {
        return supportedPlaybackRates
    }
    
    /// 获取支持的媒体格式
    func getSupportedMediaFormats() -> [String] {
        return supportedMediaFormats
    }
    
    // MARK: - Event Handling
    
    /// 注册渲染器事件监听器
    /// - Parameter listener: 事件监听器
    func registerEventListener(_ listener: DLNARendererEventListener) {
        if !eventListeners.contains(where: { $0 === listener }) {
            eventListeners.append(listener)
        }
    }
    
    /// 移除渲染器事件监听器
    /// - Parameter listener: 事件监听器
    func removeEventListener(_ listener: DLNARendererEventListener) {
        if let index = eventListeners.firstIndex(where: { $0 === listener }) {
            eventListeners.remove(at: index)
        }
    }
    
    /// 移除所有渲染器事件监听器
    func removeAllEventListeners() {
        eventListeners.removeAll()
    }
    
    // MARK: - MacastPlugin Methods
    
    /// 加载插件
    func load() throws {
        if !isLoaded {
            // 更新加载状态
            isLoaded = true
            
            // 调用插件加载完成方法
            pluginDidLoad()
        }
    }
    
    /// 卸载插件
    func unload() throws {
        if isLoaded {
            // 停止当前播放
            try stop()
            
            // 移除所有事件监听器
            removeAllEventListeners()
            
            // 更新加载状态
            isLoaded = false
            
            // 调用插件卸载完成方法
            pluginDidUnload()
        }
    }
    
    /// 启用插件
    func enable() throws {
        if !isEnabled {
            // 启用渲染器
            isEnabled = true
            
            // 调用插件启用完成方法
            pluginDidEnable()
        }
    }
    
    /// 禁用插件
    func disable() throws {
        if isEnabled {
            // 停止当前播放
            try stop()
            
            // 禁用渲染器
            isEnabled = false
            
            // 调用插件禁用完成方法
            pluginDidDisable()
        }
    }
    
    /// 插件配置变更
    func configurationChanged() {
        // 处理配置变更
        print("QuickTime渲染器配置已变更")
    }
    
    // MARK: - Private Methods
    
    /// 更新当前媒体信息
    private func updateCurrentMediaInfo() {
        // 获取媒体时长
        var duration = 0.0
        if let result = try? appleScriptController.runAppleScript("tell application \"QuickTime Player\" to get duration of first document") {
            duration = Double(result) ?? 0.0
        }
        
        // 获取媒体标题
        var title: String?
        if let result = try? appleScriptController.runAppleScript("tell application \"QuickTime Player\" to get name of first document") {
            if !result.isEmpty {
                title = result
            }
        }
        
        // 更新媒体信息
        currentMediaInfo = DLNAMediaInfo(
        duration: duration,
        mediaURL: URL(string: "")!,
        title: title,
        author: nil,
        album: nil,
        format: nil,
        size: nil,
        bitrate: nil,
        sampleRate: nil,
        channels: nil,
        resolution: nil,
        frameRate: nil
    )
        
        // 通知媒体信息变更
        notifyMediaInfoChanged()
    }
    
    /// 通知播放状态变更
    private func notifyPlaybackStateChanged() {
        for listener in eventListeners {
            listener.renderer(self, playbackStateChanged: playbackState)
        }
    }
    
    /// 通知媒体信息变更
    private func notifyMediaInfoChanged() {
        if let info = currentMediaInfo {
            for listener in eventListeners {
                listener.renderer(self, mediaLoaded: info)
            }
        }
    }
    
    /// 通知音量变更
    private func notifyVolumeChanged() {
        for listener in eventListeners {
            listener.renderer(self, volumeChanged: volumeInfo.volume)
            listener.renderer(self, muteChanged: volumeInfo.muted)
        }
    }
}

// MARK: - QuickTimeAppleScriptController

/// QuickTime AppleScript控制器，用于执行AppleScript命令
class QuickTimeAppleScriptController {
    
    /// 执行AppleScript命令
    /// - Parameter script: AppleScript脚本
    /// - Returns: 执行结果
    func runAppleScript(_ script: String) throws -> String {
        let scriptObject = NSAppleScript(source: script)
        var errorInfo: NSDictionary?
        
        guard let result = scriptObject?.executeAndReturnError(&errorInfo) else {
            if let error = errorInfo {
                throw QuickTimeRendererError.appleScriptError(error.description)
            } else {
                throw QuickTimeRendererError.appleScriptExecutionFailed
            }
        }
        
        return result.stringValue ?? ""
    }
}

// MARK: - QuickTimeRendererError

/// QuickTime渲染器错误枚举
enum QuickTimeRendererError: Error, LocalizedError {
    case appleScriptError(String)
    case appleScriptExecutionFailed
    case unsupportedPlaybackRate
    case playbackFailed
    case volumeControlFailed
    case seekFailed
    
    var errorDescription: String? {
        switch self {
        case .appleScriptError(let message):
            return "AppleScript执行错误: \(message)"
        case .appleScriptExecutionFailed:
            return "AppleScript执行失败"
        case .unsupportedPlaybackRate:
            return "不支持的播放速率"
        case .playbackFailed:
            return "播放失败"
        case .volumeControlFailed:
            return "音量控制失败"
        case .seekFailed:
            return "跳转到指定位置失败"
        }
    }
}
