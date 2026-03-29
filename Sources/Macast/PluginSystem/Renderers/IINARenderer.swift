import Foundation
import ScriptingBridge
import AppKit

// MARK: - IINA Application Protocol

/// IINA应用程序的AppleScript协议
@objc protocol IINAApplication {
    // 基本属性
    @objc optional var name: String { get }
    @objc optional var version: String { get }
    
    // 播放控制方法
    @objc optional func play()
    @objc optional func pause()
    @objc optional func stop()
    @objc optional func next()
    @objc optional func previous()
    @objc optional func seek(_ amount: Any, by: Any)
    @objc optional func setPosition(_ position: Any)
    @objc optional func setSpeed(_ speed: Any)
    
    // 音量控制方法
    @objc optional func setVolume(_ volume: Any)
    @objc optional func setMuted(_ muted: Any)
    
    // 文件操作方法
    @objc optional func openLocation(_ location: Any)
    
    // 属性
    @objc optional var position: Any { get set }
    @objc optional var volume: Any { get set }
    @objc optional var muted: Bool { get set }
    @objc optional var playing: Bool { get }
    @objc optional var paused: Bool { get }
    @objc optional var stopped: Bool { get }
    @objc optional var speed: Any { get set }
    @objc optional var currentTrack: AnyObject? { get }
}

// MARK: - IINATrack Protocol

/// IINA轨道的AppleScript协议
@objc protocol IINATrack {
    @objc optional var name: String { get }
    @objc optional var album: String { get }
    @objc optional var artist: String { get }
    @objc optional var duration: Any { get }
    @objc optional var location: Any { get }
}

// MARK: - Scripting Bridge Extension

/// 将IINA应用程序与Scripting Bridge连接
extension SBApplication: IINAApplication {
}

/// 将IINA轨道与Scripting Bridge连接
extension SBElementArray: IINATrack {
}

// MARK: - IINARenderer

/// IINA播放器渲染器插件
class IINARenderer: NSObject, DLNARendererProtocol {
    
    // MARK: - MacastPlugin Properties
    
    /// 插件的唯一标识符
    var identifier: String = "com.macast.renderer.iina"
    
    /// 插件名称
    var name: String = "IINA Renderer"
    
    /// 插件版本
    var version: String = "1.0.0"
    
    /// 插件作者
    var author: String = "Macast Team"
    
    /// 插件主页
    var homepage: URL? = URL(string: "https://iina.io/")
    
    /// 插件是否已启用
    var isEnabled: Bool = true
    
    /// 插件是否已加载
    var isLoaded: Bool = false
    
    // MARK: - MacastPlugin Properties (override NSObject's description)
    
    /// 插件描述（覆盖NSObject的description属性）
    override var description: String {
        get { "IINA媒体播放器渲染器插件" }
    }
    
    // MARK: - DLNARenderer Properties
    
    /// 渲染器的友好名称
    var friendlyName: String = "IINA Renderer"
    
    /// 渲染器的UDN (Unique Device Name)
    var udn: String = "uuid:iina-renderer-" + UUID().uuidString
    
    /// 渲染器的型号名称
    var modelName: String = "IINA"
    
    /// 渲染器的制造商
    var manufacturer: String = "IINA Team"
    
    /// 渲染器的当前状态
    var playbackState: DLNAPlaybackState = .stopped
    
    /// 当前播放的媒体信息
    var currentMediaInfo: DLNAMediaInfo?
    
    /// 音量信息
    var volumeInfo: DLNAVolumeInfo = DLNAVolumeInfo(volume: 50, maxVolume: 100, muted: false)
    
    /// 支持的播放速率
    var supportedPlaybackRates: [String] = ["0.5", "1", "2"]
    
    /// 支持的媒体格式
    var supportedMediaFormats: [String] = [
        "video/mpeg", "video/mp4", "video/avi", "video/quicktime",
        "video/x-matroska", "video/webm", "video/flv", "video/x-ms-wmv",
        "audio/mpeg", "audio/mp4", "audio/aac", "audio/wav", "audio/flac", "audio/ogg",
        "audio/x-m4a", "audio/x-ms-wma"
    ]
    
    // MARK: - Private Properties
    
    /// IINA应用程序实例
    private var iinaApp: IINAApplication?
    
    /// 事件监听器
    private var eventListeners: [DLNARendererEventListener] = []
    
    /// 播放状态定时器
    private var playbackStateTimer: Timer?
    
    // MARK: - Lifecycle Methods
    
    /// 初始化插件
    required override init() {
        super.init()
        
        // 初始化IINA应用程序实例
        initializeIINA()
    }
    
    /// 加载插件
    func load() throws {
        if !isLoaded {
            // 启动播放状态监听
            startPlaybackStateMonitoring()
            
            // 更新加载状态
            isLoaded = true
            
            // 调用插件加载完成方法
            pluginDidLoad()
        }
    }
    
    /// 卸载插件
    func unload() throws {
        if isLoaded {
            // 停止播放状态监听
            stopPlaybackStateMonitoring()
            
            // 停止IINA应用程序
            stopIINA()
            
            // 更新加载状态
            isLoaded = false
            
            // 调用插件卸载完成方法
            pluginDidUnload()
        }
    }
    
    /// 启用插件
    func enable() throws {
        isEnabled = true
        pluginDidEnable()
    }
    
    /// 禁用插件
    func disable() throws {
        isEnabled = false
        pluginDidDisable()
    }
    
    /// 插件配置变更
    func configurationChanged() {
        // 处理配置变更
    }
    
    // MARK: - Playback Control Methods
    
    /// 加载媒体
    func loadMedia(mediaURL: URL, position: Double) throws {
        // 确保IINA已启动
        guard ensureIINAStarted() else {
            throw IINARendererError.applicationNotFound
        }
        
        // 打开媒体URL
        iinaApp?.openLocation?(mediaURL.absoluteString as NSString)
        
        // 更新当前媒体信息
        currentMediaInfo = DLNAMediaInfo(
            duration: 0, // 将在播放状态更新时获取
            mediaURL: mediaURL,
            title: nil,
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
        
        // 如果需要，跳转到指定位置
        if position > 0 {
            try seekTo(position: position)
        }
        
        // 更新播放状态
        updatePlaybackState()
    }
    
    /// 播放
    func play() throws {
        guard ensureIINAStarted() else {
            throw IINARendererError.applicationNotFound
        }
        
        iinaApp?.play?()
        updatePlaybackState()
    }
    
    /// 暂停
    func pause() throws {
        guard ensureIINAStarted() else {
            throw IINARendererError.applicationNotFound
        }
        
        iinaApp?.pause?()
        updatePlaybackState()
    }
    
    /// 停止
    func stop() throws {
        guard ensureIINAStarted() else {
            throw IINARendererError.applicationNotFound
        }
        
        iinaApp?.stop?()
        updatePlaybackState()
    }
    
    /// 快进
    func seekForward(seconds: Double) throws {
        try seekTo(position: getCurrentPosition() + seconds)
    }
    
    /// 快退
    func seekBackward(seconds: Double) throws {
        try seekTo(position: max(0, getCurrentPosition() - seconds))
    }
    
    /// 跳转到指定位置
    func seekTo(position: Double) throws {
        guard ensureIINAStarted() else {
            throw IINARendererError.applicationNotFound
        }
        
        iinaApp?.setPosition?(NSNumber(value: position))
        updatePlaybackState()
    }
    
    /// 设置播放速率
    func setPlaybackRate(rate: Double) throws {
        guard ensureIINAStarted() else {
            throw IINARendererError.applicationNotFound
        }
        
        // 检查是否支持该播放速率
        if !supportedPlaybackRates.contains(String(rate)) {
            throw DLNARendererError.unsupportedFeature("不支持的播放速率: \(rate)")
        }
        
        iinaApp?.setSpeed?(NSNumber(value: rate))
        updatePlaybackState()
    }
    
    /// 获取当前播放位置
    func getCurrentPosition() -> Double {
        guard ensureIINAStarted() else {
            return 0
        }
        
        if let position = iinaApp?.position as? Double {
            return position
        }
        
        return 0
    }
    
    /// 获取当前媒体信息
    func getMediaInfo() -> DLNAMediaInfo? {
        return currentMediaInfo
    }
    
    // MARK: - Volume Control Methods
    
    /// 设置音量
    func setVolume(volume: Int) throws {
        guard ensureIINAStarted() else {
            throw IINARendererError.applicationNotFound
        }
        
        let normalizedVolume = Double(volume) / 100.0
        iinaApp?.setVolume?(NSNumber(value: normalizedVolume))
        
        // 更新音量信息
        volumeInfo.volume = volume
        notifyVolumeChanged(volume: volume)
    }
    
    /// 增加音量
    func increaseVolume(delta: Int) throws {
        let newVolume = min(100, volumeInfo.volume + delta)
        try setVolume(volume: newVolume)
    }
    
    /// 减少音量
    func decreaseVolume(delta: Int) throws {
        let newVolume = max(0, volumeInfo.volume - delta)
        try setVolume(volume: newVolume)
    }
    
    /// 设置静音状态
    func setMuted(muted: Bool) throws {
        guard ensureIINAStarted() else {
            throw IINARendererError.applicationNotFound
        }
        
        iinaApp?.setMuted?(muted)
        
        // 更新音量信息
        volumeInfo.muted = muted
        notifyMuteChanged(muted: muted)
    }
    
    // MARK: - Event Handling
    
    /// 注册渲染器事件监听器
    func registerEventListener(_ listener: DLNARendererEventListener) {
        if !eventListeners.contains(where: { $0 === listener }) {
            eventListeners.append(listener)
        }
    }
    
    /// 移除渲染器事件监听器
    func removeEventListener(_ listener: DLNARendererEventListener) {
        eventListeners.removeAll(where: { $0 === listener })
    }
    
    /// 移除所有渲染器事件监听器
    func removeAllEventListeners() {
        eventListeners.removeAll()
    }
    
    // MARK: - Private Methods
    
    /// 初始化IINA应用程序实例
    private func initializeIINA() {
        // 使用Bundle Identifier获取IINA应用程序实例
        iinaApp = SBApplication(bundleIdentifier: "com.colliderli.iina") as? IINAApplication
    }
    
    /// 确保IINA应用程序已启动
    private func ensureIINAStarted() -> Bool {
        // 检查IINA是否已运行
        if iinaApp == nil {
            // 尝试启动IINA应用程序
            let iinaURL = URL(fileURLWithPath: "/Applications/IINA.app")
            let configuration = NSWorkspace.OpenConfiguration()
            
            do {
                try NSWorkspace.shared.openApplication(at: iinaURL, configuration: configuration)
                
                // 等待IINA启动
                Thread.sleep(forTimeInterval: 1.0)
                
                // 重新获取IINA应用程序实例
                initializeIINA()
            } catch {
                print("启动IINA应用程序失败: \(error.localizedDescription)")
                return false
            }
        }
        
        return true
    }
    
    /// 停止IINA应用程序
    private func stopIINA() {
        if iinaApp != nil {
            iinaApp?.stop?()
        }
    }
    
    /// 更新播放状态
    private func updatePlaybackState() {
        guard ensureIINAStarted() else {
            playbackState = .stopped
            return
        }
        
        // 检查播放状态
        if iinaApp?.playing ?? false {
            playbackState = .playing
        } else if iinaApp?.paused ?? false {
            playbackState = .paused
        } else if iinaApp?.stopped ?? false {
            playbackState = .stopped
        } else {
            playbackState = .unknown
        }
        
        // 更新媒体信息
        updateMediaInfo()
        
        // 更新音量信息
        updateVolumeInfo()
        
        // 通知播放状态变化
        notifyPlaybackStateChanged(state: playbackState)
        
        // 如果播放结束，通知事件监听器
        if playbackState == .stopped && currentMediaInfo != nil {
            notifyPlaybackFinished()
            currentMediaInfo = nil
        }
    }
    
    /// 更新媒体信息
    private func updateMediaInfo() {
        guard ensureIINAStarted() else {
            return
        }
        
        // 获取当前轨道信息
        if let currentTrack = iinaApp?.currentTrack as? IINATrack {
            // 获取媒体时长
            var duration: Double = 0
            if let trackDuration = currentTrack.duration as? Double {
                duration = trackDuration
            } else if let trackDuration = currentTrack.duration as? Int {
                duration = Double(trackDuration)
            }
            
            // 获取媒体URL
            var mediaURL: URL?
            if let location = currentTrack.location as? String {
                mediaURL = URL(string: location)
            }
            
            // 更新媒体信息
            if let url = mediaURL {
                currentMediaInfo = DLNAMediaInfo(
                    duration: duration,
                    mediaURL: url,
                    title: currentTrack.name,
                    author: currentTrack.artist,
                    album: currentTrack.album,
                    format: nil,
                    size: nil,
                    bitrate: nil,
                    sampleRate: nil,
                    channels: nil,
                    resolution: nil,
                    frameRate: nil
                )
                
                // 通知媒体加载完成
                notifyMediaLoaded(mediaInfo: currentMediaInfo!)
            }
        }
    }
    
    /// 更新音量信息
    private func updateVolumeInfo() {
        guard ensureIINAStarted() else {
            return
        }
        
        // 获取音量
        if let volume = iinaApp?.volume as? Double {
            let normalizedVolume = Int(volume * 100.0)
            volumeInfo.volume = normalizedVolume
        }
        
        // 获取静音状态
        if let muted = iinaApp?.muted {
            volumeInfo.muted = muted
        }
    }
    
    /// 启动播放状态监听
    private func startPlaybackStateMonitoring() {
        // 创建定时器，定期更新播放状态
        playbackStateTimer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(playbackStateTimerFired),
            userInfo: nil,
            repeats: true
        )
        
        // 立即更新一次播放状态
        updatePlaybackState()
    }
    
    /// 停止播放状态监听
    private func stopPlaybackStateMonitoring() {
        // 停止定时器
        playbackStateTimer?.invalidate()
        playbackStateTimer = nil
    }
    
    /// 播放状态定时器回调
    @objc private func playbackStateTimerFired() {
        updatePlaybackState()
    }
    
    // MARK: - Event Notification Methods
    
    /// 通知播放状态变化
    private func notifyPlaybackStateChanged(state: DLNAPlaybackState) {
        for listener in eventListeners {
            listener.renderer(self, playbackStateChanged: state)
        }
    }
    
    /// 通知媒体加载完成
    private func notifyMediaLoaded(mediaInfo: DLNAMediaInfo) {
        for listener in eventListeners {
            listener.renderer(self, mediaLoaded: mediaInfo)
        }
    }
    
    /// 通知播放位置变化
    private func notifyPositionChanged(position: Double) {
        for listener in eventListeners {
            listener.renderer(self, positionChanged: position)
        }
    }
    
    /// 通知音量变化
    private func notifyVolumeChanged(volume: Int) {
        for listener in eventListeners {
            listener.renderer(self, volumeChanged: volume)
        }
    }
    
    /// 通知静音状态变化
    private func notifyMuteChanged(muted: Bool) {
        for listener in eventListeners {
            listener.renderer(self, muteChanged: muted)
        }
    }
    
    /// 通知播放结束
    private func notifyPlaybackFinished() {
        for listener in eventListeners {
            listener.rendererDidFinishPlayback(self)
        }
    }
    
    /// 通知错误
    private func notifyError(error: Error) {
        for listener in eventListeners {
            listener.renderer(self, didEncounterError: error)
        }
    }
}

// MARK: - IINARendererError

/// IINA渲染器错误枚举
enum IINARendererError: Error, LocalizedError {
    case applicationNotFound
    case commandFailed
    case mediaLoadFailed
    
    var errorDescription: String? {
        switch self {
        case .applicationNotFound:
            return "IINA应用程序未找到"
        case .commandFailed:
            return "命令执行失败"
        case .mediaLoadFailed:
            return "媒体加载失败"
        }
    }
}
