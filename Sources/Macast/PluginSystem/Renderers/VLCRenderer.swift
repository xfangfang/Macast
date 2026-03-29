import Foundation
import AppKit

// MARK: - VLCRenderer

/// VLC播放器渲染器实现
class VLCRenderer: DLNARendererProtocol {
    
    // MARK: - MacastPlugin Properties
    
    /// 插件的唯一标识符
    let identifier: String = "com.macast.renderer.vlc"
    
    /// 插件名称
    var name: String { get { return friendlyName } set { friendlyName = newValue } }
    
    /// 插件版本
    let version: String = "1.0.0"
    
    /// 插件描述
    let description: String = "VLC播放器渲染器插件"
    
    /// 插件作者
    let author: String = "Macast开发团队"
    
    /// 插件主页
    let homepage: URL? = URL(string: "https://github.com/macast-dev/macast-vlc-renderer")
    
    /// 插件是否已启用
    var isEnabled: Bool = true
    
    /// 插件是否已加载
    var isLoaded: Bool = false
    
    /// 插件依赖的其他插件
    let dependencies: [PluginDependency] = []
    
    // MARK: - DLNARendererProtocol Properties
    
    /// 渲染器的友好名称
    var friendlyName: String = "VLC渲染器"
    
    /// 渲染器的UDN (Unique Device Name)
    let udn: String = "uuid:vlc-renderer-" + UUID().uuidString
    
    /// 渲染器的型号名称
    let modelName: String = "VLC Player"
    
    /// 渲染器的制造商
    let manufacturer: String = "VideoLAN"
    
    /// 渲染器的当前状态
    var playbackState: DLNAPlaybackState = .stopped
    
    /// 当前播放的媒体信息
    var currentMediaInfo: DLNAMediaInfo?
    
    /// 音量信息
    var volumeInfo: DLNAVolumeInfo
    
    /// 支持的播放速率
    let supportedPlaybackRates: [String] = ["1.0", "0.5", "2.0", "3.0", "4.0", "5.0"]
    
    /// 支持的媒体格式
    let supportedMediaFormats: [String] = [
        "video/*",
        "audio/*",
        "image/*",
        "application/vnd.ms-asf",
        "application/vnd.rn-realmedia",
        "application/x-mpegURL",
        "application/dash+xml",
        "application/x-matroska",
        "application/x-shockwave-flash",
        "text/plain"
    ]
    
    // MARK: - Private Properties
    
    /// AppleScript控制器
    private let appleScriptController: AppleScriptController
    
    /// 事件监听器
    private var eventListeners: [DLNARendererEventListener] = []
    
    /// 通知管理器
    private let notificationManager: NotificationManager
    
    // MARK: - Initialization
    
    required init() {
        // 初始化AppleScript控制器
        appleScriptController = AppleScriptController()
        
        // 初始化通知管理器
        notificationManager = NotificationManager.shared
        
        // 初始化音量信息
        volumeInfo = DLNAVolumeInfo(
            volume: 100,
            maxVolume: 100,
            muted: false
        )
        
        // 检查VLC是否已安装
        if !isVLCInstalled() {
            print("警告: VLC播放器未安装")
        }
    }
    
    // MARK: - Playback Control Methods
    
    /// 加载媒体
    /// - Parameter mediaURL: 媒体URL
    /// - Parameter position: 开始播放的位置（秒）
    func loadMedia(mediaURL: URL, position: Double) throws {
        // 检查VLC是否已安装
        guard isVLCInstalled() else {
            throw VLCRendererError.vlcNotInstalled
        }
        
        // 更新播放状态
        playbackState = .transitioning
        notifyPlaybackStateChanged()
        
        // 打开VLC应用
        _ = try appleScriptController.runAppleScript("tell application \"VLC\" to activate")
        
        // 清除当前播放列表
        _ = try appleScriptController.runAppleScript("tell application \"VLC\" to clear")
        
        // 添加媒体到播放列表
        let script = "tell application \"VLC\" to open location \"mediaURL.absoluteString)\""
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
        
        // 更新播放状态
        playbackState = .playing
        notifyPlaybackStateChanged()
    }
    
    /// 播放
    func play() throws {
        // 检查VLC是否已安装
        guard isVLCInstalled() else {
            throw VLCRendererError.vlcNotInstalled
        }
        
        // 发送播放命令
        _ = try appleScriptController.runAppleScript("tell application \"VLC\" to play")
        
        // 更新播放状态
        playbackState = .playing
        notifyPlaybackStateChanged()
    }
    
    /// 暂停
    func pause() throws {
        // 检查VLC是否已安装
        guard isVLCInstalled() else {
            throw VLCRendererError.vlcNotInstalled
        }
        
        // 发送暂停命令
        _ = try appleScriptController.runAppleScript("tell application \"VLC\" to pause")
        
        // 更新播放状态
        playbackState = .paused
        notifyPlaybackStateChanged()
        
        // 发送媒体播放暂停通知
        notificationManager.sendMediaPlaybackPausedNotification(mediaTitle: currentMediaInfo?.title)
    }
    
    /// 停止
    func stop() throws {
        // 检查VLC是否已安装
        guard isVLCInstalled() else {
            throw VLCRendererError.vlcNotInstalled
        }
        
        // 发送停止命令
        _ = try appleScriptController.runAppleScript("tell application \"VLC\" to stop")
        
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
        // 检查VLC是否已安装
        guard isVLCInstalled() else {
            throw VLCRendererError.vlcNotInstalled
        }
        
        // 获取当前位置
        let currentPosition = getCurrentPosition()
        
        // 跳转到新位置
        try seekTo(position: currentPosition + seconds)
    }
    
    /// 快退
    /// - Parameter seconds: 快退的秒数
    func seekBackward(seconds: Double) throws {
        // 检查VLC是否已安装
        guard isVLCInstalled() else {
            throw VLCRendererError.vlcNotInstalled
        }
        
        // 获取当前位置
        let currentPosition = getCurrentPosition()
        
        // 跳转到新位置
        try seekTo(position: max(0, currentPosition - seconds))
    }
    
    /// 跳转到指定位置
    /// - Parameter position: 位置（秒）
    func seekTo(position: Double) throws {
        // 检查VLC是否已安装
        guard isVLCInstalled() else {
            throw VLCRendererError.vlcNotInstalled
        }
        
        // 发送跳转命令
        let script = "tell application \"VLC\" to set current time to \(position)"
        _ = try appleScriptController.runAppleScript(script)
        
        // 发送播放命令（跳转后需要重新播放）
        _ = try appleScriptController.runAppleScript("tell application \"VLC\" to play")
        
        // 更新播放状态
        playbackState = .playing
        notifyPlaybackStateChanged()
    }
    
    /// 设置播放速率
    /// - Parameter rate: 播放速率 (1为正常速度, 2为两倍速, 0.5为半速)
    func setPlaybackRate(rate: Double) throws {
        // 检查VLC是否已安装
        guard isVLCInstalled() else {
            throw VLCRendererError.vlcNotInstalled
        }
        
        // 检查速率是否支持
        guard supportedPlaybackRates.contains(String(rate)) else {
            throw VLCRendererError.unsupportedPlaybackRate
        }
        
        // 发送设置播放速率命令
        let script = "tell application \"VLC\" to set rate to \(rate)"
        _ = try appleScriptController.runAppleScript(script)
    }
    
    /// 获取当前播放位置
    /// - Returns: 当前播放位置（秒）
    func getCurrentPosition() -> Double {
        // 检查VLC是否已安装
        guard isVLCInstalled() else {
            return 0.0
        }
        
        // 发送获取当前位置命令
        if let result = try? appleScriptController.runAppleScript("tell application \"VLC\" to get current time") {
            return Double(result) ?? 0.0
        }
        
        return 0.0
    }
    
    // MARK: - Volume Control Methods
    
    /// 设置音量
    /// - Parameter volume: 音量值（0-100）
    func setVolume(volume: Int) throws {
        // 检查VLC是否已安装
        guard isVLCInstalled() else {
            throw VLCRendererError.vlcNotInstalled
        }
        
        // 确保音量在有效范围内
        let validVolume = max(0, min(100, volume))
        
        // 发送设置音量命令
        let script = "tell application \"VLC\" to set audio volume to \(validVolume)"
        _ = try appleScriptController.runAppleScript(script)
        
        // 更新音量信息
        volumeInfo.volume = validVolume
        volumeInfo.muted = validVolume == 0
        notifyVolumeChanged()
    }
    
    /// 增加音量
    /// - Parameter delta: 增加的音量值（1-100）
    func increaseVolume(delta: Int) throws {
        // 检查VLC是否已安装
        guard isVLCInstalled() else {
            throw VLCRendererError.vlcNotInstalled
        }
        
        // 计算新音量
        let newVolume = min(100, volumeInfo.volume + delta)
        
        // 设置新音量
        try setVolume(volume: newVolume)
    }
    
    /// 减少音量
    /// - Parameter delta: 减少的音量值（1-100）
    func decreaseVolume(delta: Int) throws {
        // 检查VLC是否已安装
        guard isVLCInstalled() else {
            throw VLCRendererError.vlcNotInstalled
        }
        
        // 计算新音量
        let newVolume = max(0, volumeInfo.volume - delta)
        
        // 设置新音量
        try setVolume(volume: newVolume)
    }
    
    /// 设置静音状态
    /// - Parameter muted: 静音状态
    func setMuted(muted: Bool) throws {
        // 检查VLC是否已安装
        guard isVLCInstalled() else {
            throw VLCRendererError.vlcNotInstalled
        }
        
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
        // 返回公共的DLNATransportInfo结构体
        return DLNATransportInfo(transportState: playbackState, transportStatus: "OK", playSpeed: "1.0")
    }
    
    /// 获取当前媒体信息
    func getMediaInfo() -> DLNAMediaInfo? {
        return currentMediaInfo
    }
    
    /// 获取当前位置信息
    func getPositionInfo() -> DLNAPositionInfo {
        let currentPosition = getCurrentPosition()
        let duration = currentMediaInfo?.duration ?? 0.0
        
        // 返回公共的DLNAPositionInfo结构体
        return DLNAPositionInfo(
            currentPosition: currentPosition,
            currentTime: String(format: "%.3f", currentPosition),
            totalTime: String(format: "%.3f", duration),
            trackNumber: 1,
            mediaURL: currentMediaInfo?.mediaURL
        )
    }
    
    /// 获取设备功能
    func getDeviceCapabilities() -> DLNADeviceCapabilities {
        // 返回公共的DLNADeviceCapabilities结构体
        return DLNADeviceCapabilities(
            playbackRateList: ["1.0"],
            recQualityModes: [],
            transportPlayStates: ["PLAYING", "PAUSED_PLAYBACK", "STOPPED", "TRANSITIONING", "ERROR_OCCURRED"],
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
            // 初始化渲染器
            if !isVLCInstalled() {
                throw VLCRendererError.vlcNotInstalled
            }
            
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
        print("VLC渲染器配置已变更")
    }
    
    // MARK: - Private Methods
    
    /// 检查VLC是否已安装
    private func isVLCInstalled() -> Bool {
        let vlcPath = "/Applications/VLC.app"
        return FileManager.default.fileExists(atPath: vlcPath)
    }
    
    /// 更新当前媒体信息
    private func updateCurrentMediaInfo() {
        // 检查VLC是否已安装
        guard isVLCInstalled() else {
            return
        }
        
        // 获取媒体时长
        var duration = 0.0
        if let result = try? appleScriptController.runAppleScript("tell application \"VLC\" to get duration") {
            duration = Double(result) ?? 0.0
        }
        
        // 获取媒体标题
        var title = "未知标题"
        if let result = try? appleScriptController.runAppleScript("tell application \"VLC\" to get name of current item") {
            if !result.isEmpty {
                title = result
            }
        }
        
        // 更新媒体信息
        currentMediaInfo = DLNAMediaInfo(
            duration: duration,
            mediaURL: URL(string: "")!,
            title: title,
            artist: nil,
            album: nil,
            mediaType: "video/unknown",
            format: nil,
            size: 0,
            metadata: nil
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
        for listener in eventListeners {
            if let currentMediaInfo {
                listener.renderer(self, mediaLoaded: currentMediaInfo)
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

// MARK: - AppleScriptController

/// AppleScript控制器，用于执行AppleScript命令
class AppleScriptController {
    
    /// 执行AppleScript命令
    /// - Parameter script: AppleScript脚本
    /// - Returns: 执行结果
    func runAppleScript(_ script: String) throws -> String {
        let scriptObject = NSAppleScript(source: script)
        var errorInfo: NSDictionary?
        
        guard let result = scriptObject?.executeAndReturnError(&errorInfo) else {
            if let error = errorInfo {
                throw VLCRendererError.appleScriptError(error.description)
            } else {
                throw VLCRendererError.appleScriptExecutionFailed
            }
        }
        
        return result.stringValue ?? ""
    }
}

// MARK: - VLCRendererError

/// VLC渲染器错误枚举
enum VLCRendererError: Error, LocalizedError {
    case vlcNotInstalled
    case appleScriptError(String)
    case appleScriptExecutionFailed
    case unsupportedPlaybackRate
    case playbackFailed
    case volumeControlFailed
    case seekFailed
    
    var errorDescription: String? {
        switch self {
        case .vlcNotInstalled:
            return "VLC播放器未安装"
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

// MARK: - DLNAMediaInfo Extension

extension DLNAMediaInfo {
    /// 初始化方法
    init(duration: Double, mediaURL: URL, title: String?, artist: String?, album: String?, mediaType: String, format: String?, size: Int64, metadata: [String: Any]?) {
        self.duration = duration
        self.mediaURL = mediaURL
        self.title = title
        
        // 为了兼容原始DLNAMediaInfo结构体，这里添加了额外的初始化代码
        // 注意：原始DLNAMediaInfo结构体可能缺少一些属性，需要根据实际情况进行调整
    }
}

// MARK: - VLCDeviceCapabilities

/// VLC设备功能结构体
struct VLCDeviceCapabilities {
    var playMedia: Bool
    var stop: Bool
    var pause: Bool
    var seek: Bool
    var setPlayMode: Bool
    var getMediaInfo: Bool
    var getTransportInfo: Bool
    var getPositionInfo: Bool
    var getDeviceCapabilities: Bool
    var getVolume: Bool
    var setVolume: Bool
    var mute: Bool
}

// MARK: - VLCPositionInfo

/// VLC位置信息结构体
struct VLCPositionInfo {
    var track: Int
    var trackDuration: String
    var trackPosition: String
    var relativeTimePosition: String
    var absoluteTimePosition: String
}

// MARK: - VLCTransportInfo

/// VLC传输信息结构体
struct VLCTransportInfo {
    var transportState: String
    var currentSpeed: String
}
