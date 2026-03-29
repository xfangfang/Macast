import Foundation
import Network

// MARK: - DLNARendererProtocol Protocol

/// DLNA渲染器插件的协议
public protocol DLNARendererProtocol: MacastPlugin {
    
    // MARK: - Basic Properties
    
    /// 渲染器的友好名称
    var friendlyName: String { get set }
    
    /// 渲染器的UDN (Unique Device Name)
    var udn: String { get }
    
    /// 渲染器的型号名称
    var modelName: String { get }
    
    /// 渲染器的制造商
    var manufacturer: String { get }
    
    /// 渲染器的当前状态
    var playbackState: DLNAPlaybackState { get }
    
    /// 当前播放的媒体信息
    var currentMediaInfo: DLNAMediaInfo? { get }
    
    /// 音量信息
    var volumeInfo: DLNAVolumeInfo { get }
    
    /// 支持的播放速率
    var supportedPlaybackRates: [String] { get }
    
    /// 支持的媒体格式
    var supportedMediaFormats: [String] { get }
    
    // MARK: - Playback Control Methods
    
    /// 加载媒体
    /// - Parameter mediaURL: 媒体URL
    /// - Parameter position: 开始播放的位置（秒）
    func loadMedia(mediaURL: URL, position: Double) throws
    
    /// 播放
    func play() throws
    
    /// 暂停
    func pause() throws
    
    /// 停止
    func stop() throws
    
    /// 快进
    /// - Parameter seconds: 快进的秒数
    func seekForward(seconds: Double) throws
    
    /// 快退
    /// - Parameter seconds: 快退的秒数
    func seekBackward(seconds: Double) throws
    
    /// 跳转到指定位置
    /// - Parameter position: 位置（秒）
    func seekTo(position: Double) throws
    
    /// 设置播放速率
    /// - Parameter rate: 播放速率 (1为正常速度, 2为两倍速, 0.5为半速)
    func setPlaybackRate(rate: Double) throws
    
    /// 获取当前播放位置
    /// - Returns: 当前播放位置（秒）
    func getCurrentPosition() -> Double
    
    // MARK: - Volume Control Methods
    
    /// 设置音量
    /// - Parameter volume: 音量值（0-100）
    func setVolume(volume: Int) throws
    
    /// 增加音量
    /// - Parameter delta: 增加的音量值（1-100）
    func increaseVolume(delta: Int) throws
    
    /// 减少音量
    /// - Parameter delta: 减少的音量值（1-100）
    func decreaseVolume(delta: Int) throws
    
    /// 设置静音状态
    /// - Parameter muted: 静音状态
    func setMuted(muted: Bool) throws
    
    // MARK: - Transport Control Methods
    
    /// 获取当前传输状态
    func getTransportInfo() -> DLNATransportInfo
    
    /// 获取当前媒体信息
    func getMediaInfo() -> DLNAMediaInfo?
    
    /// 获取当前位置信息
    func getPositionInfo() -> DLNAPositionInfo
    
    /// 获取设备功能
    func getDeviceCapabilities() -> DLNADeviceCapabilities
    
    /// 获取播放速率列表
    func getPlaybackRateList() -> [String]
    
    /// 获取支持的媒体格式
    func getSupportedMediaFormats() -> [String]
    
    // MARK: - Event Handling
    
    /// 注册渲染器事件监听器
    /// - Parameter listener: 事件监听器
    func registerEventListener(_ listener: DLNARendererEventListener)
    
    /// 移除渲染器事件监听器
    /// - Parameter listener: 事件监听器
    func removeEventListener(_ listener: DLNARendererEventListener)
    
    /// 移除所有渲染器事件监听器
    func removeAllEventListeners()
}

// MARK: - DLNAPlaybackState

/// DLNA播放状态枚举
public enum DLNAPlaybackState: String {
    case stopped = "STOPPED"
    case playing = "PLAYING"
    case paused = "PAUSED_PLAYBACK"
    case transitioning = "TRANSITIONING"
    case error = "ERROR_OCCURRED"
    case unknown = "UNKNOWN"
}

// MARK: - DLNAMediaInfo

/// DLNA媒体信息结构体
public struct DLNAMediaInfo {
    /// 媒体时长（秒）
    var duration: Double
    
    /// 媒体URL
    var mediaURL: URL
    
    /// 媒体标题
    var title: String?
    
    /// 媒体作者
    var author: String?
    
    /// 媒体专辑
    var album: String?
    
    /// 媒体格式
    var format: String?
    
    /// 媒体大小
    var size: Int64?
    
    /// 媒体比特率
    var bitrate: Int?
    
    /// 媒体采样率
    var sampleRate: Int?
    
    /// 媒体声道数
    var channels: Int?
    
    /// 媒体分辨率
    var resolution: String?
    
    /// 媒体帧率
    var frameRate: Double?
}

// MARK: - DLNAVolumeInfo

/// DLNA音量信息结构体
public struct DLNAVolumeInfo {
    /// 当前音量（0-100）
    var volume: Int
    
    /// 最大音量
    var maxVolume: Int
    
    /// 静音状态
    var muted: Bool
}

// MARK: - DLNATransportInfo

/// DLNA传输信息结构体
public struct DLNATransportInfo {
    /// 传输状态
    var transportState: DLNAPlaybackState
    
    /// 传输状态描述
    var transportStatus: String
    
    /// 当前播放速率
    var playSpeed: String
}

// MARK: - DLNAPositionInfo

/// DLNA位置信息结构体
public struct DLNAPositionInfo {
    /// 当前播放位置（秒）
    var currentPosition: Double
    
    /// 当前播放时间（格式化字符串）
    var currentTime: String
    
    /// 媒体时长（格式化字符串）
    var totalTime: String
    
    /// 轨道编号
    var trackNumber: Int
    
    /// 媒体URL
    var mediaURL: URL?
}

// MARK: - DLNADeviceCapabilities

/// DLNA设备功能结构体
public struct DLNADeviceCapabilities {
    /// 支持的播放速率
    var playbackRateList: [String]
    
    /// 支持的记录质量模式
    var recQualityModes: [String]
    
    /// 支持的传输状态
    var transportPlayStates: [String]
    
    /// 支持的记录状态
    var transportRecStates: [String]
}

// MARK: - DLNARendererEventListener

/// DLNA渲染器事件监听器协议
public protocol DLNARendererEventListener: AnyObject {
    
    /// 播放状态变化事件
    /// - Parameter renderer: 渲染器
    /// - Parameter state: 新的播放状态
    func renderer(_ renderer: DLNARendererProtocol, playbackStateChanged state: DLNAPlaybackState)
    
    /// 媒体加载完成事件
    /// - Parameter renderer: 渲染器
    /// - Parameter mediaInfo: 媒体信息
    func renderer(_ renderer: DLNARendererProtocol, mediaLoaded mediaInfo: DLNAMediaInfo)
    
    /// 播放位置变化事件
    /// - Parameter renderer: 渲染器
    /// - Parameter position: 新的播放位置（秒）
    func renderer(_ renderer: DLNARendererProtocol, positionChanged position: Double)
    
    /// 音量变化事件
    /// - Parameter renderer: 渲染器
    /// - Parameter volume: 新的音量值
    func renderer(_ renderer: DLNARendererProtocol, volumeChanged volume: Int)
    
    /// 静音状态变化事件
    /// - Parameter renderer: 渲染器
    /// - Parameter muted: 新的静音状态
    func renderer(_ renderer: DLNARendererProtocol, muteChanged muted: Bool)
    
    /// 播放结束事件
    /// - Parameter renderer: 渲染器
    func rendererDidFinishPlayback(_ renderer: DLNARendererProtocol)
    
    /// 渲染器错误事件
    /// - Parameter renderer: 渲染器
    /// - Parameter error: 错误信息
    func renderer(_ renderer: DLNARendererProtocol, didEncounterError error: Error)
}

// MARK: - DLNARendererEventListener Default Implementation

extension DLNARendererEventListener {
    func renderer(_ renderer: DLNARendererProtocol, playbackStateChanged state: DLNAPlaybackState) {}
    func renderer(_ renderer: DLNARendererProtocol, mediaLoaded mediaInfo: DLNAMediaInfo) {}
    func renderer(_ renderer: DLNARendererProtocol, positionChanged position: Double) {}
    func renderer(_ renderer: DLNARendererProtocol, volumeChanged volume: Int) {}
    func renderer(_ renderer: DLNARendererProtocol, muteChanged muted: Bool) {}
    func rendererDidFinishPlayback(_ renderer: DLNARendererProtocol) {}
    func renderer(_ renderer: DLNARendererProtocol, didEncounterError error: Error) {}
}

// MARK: - DLNARenderer Protocol Default Implementation

extension DLNARendererProtocol {
    /// 渲染器的友好名称默认实现
    public var friendlyName: String {
        get { return name }
        set { /* 默认实现不做任何事情 */ }
    }
    
    /// 渲染器的型号名称默认实现
    public var modelName: String { return "DLNA Renderer"
    }
    
    /// 渲染器的制造商默认实现
    public var manufacturer: String { return "Macast"
    }
    
    /// 支持的播放速率默认实现
    public var supportedPlaybackRates: [String] {
        return ["1"]
    }
    
    /// 支持的媒体格式默认实现
    public var supportedMediaFormats: [String] {
        return [
            "video/mpeg", "video/mp4", "video/avi", "video/quicktime",
            "video/x-matroska", "video/webm",
            "audio/mpeg", "audio/mp4", "audio/aac", "audio/wav", "audio/flac", "audio/ogg"
        ]
    }
    
    /// 播放速率列表默认实现
    public func getPlaybackRateList() -> [String] {
        return supportedPlaybackRates
    }
    
    /// 设置播放速率默认实现
    public func setPlaybackRate(rate: Double) throws {
        // 默认实现不支持变速播放
        throw DLNARendererError.unsupportedFeature("变速播放")
    }
    
    /// 获取支持的媒体格式默认实现
    public func getSupportedMediaFormats() -> [String] {
        return supportedMediaFormats
    }
    
    /// 设备功能默认实现
    public func getDeviceCapabilities() -> DLNADeviceCapabilities {
        return DLNADeviceCapabilities(
            playbackRateList: getPlaybackRateList(),
            recQualityModes: [],
            transportPlayStates: [
                DLNAPlaybackState.stopped.rawValue,
                DLNAPlaybackState.playing.rawValue,
                DLNAPlaybackState.paused.rawValue
            ],
            transportRecStates: []
        )
    }
    
    /// 传输信息默认实现
    public func getTransportInfo() -> DLNATransportInfo {
        return DLNATransportInfo(
            transportState: playbackState,
            transportStatus: "OK",
            playSpeed: "1"
        )
    }
    
    /// 位置信息默认实现
    public func getPositionInfo() -> DLNAPositionInfo {
        let currentPosition = getCurrentPosition()
        return DLNAPositionInfo(
            currentPosition: currentPosition,
            currentTime: formatTime(seconds: currentPosition),
            totalTime: formatTime(seconds: currentMediaInfo?.duration ?? 0),
            trackNumber: 1,
            mediaURL: currentMediaInfo?.mediaURL
        )
    }
    
    /// 快进默认实现
    public func seekForward(seconds: Double) throws {
        let newPosition = getCurrentPosition() + seconds
        try seekTo(position: newPosition)
    }
    
    /// 快退默认实现
    public func seekBackward(seconds: Double) throws {
        let newPosition = max(0, getCurrentPosition() - seconds)
        try seekTo(position: newPosition)
    }
    
    /// 移除所有事件监听器默认实现
    public func removeAllEventListeners() {
        // 默认实现不做任何事情
    }
    
    /// 格式化时间为HH:MM:SS格式
    /// - Parameter seconds: 秒数
    /// - Returns: 格式化后的时间字符串
    internal func formatTime(seconds: Double) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

// MARK: - DLNARendererError

/// DLNA渲染器错误枚举
public enum DLNARendererError: Error, LocalizedError {
    case unsupportedFeature(String)
    case mediaLoadFailed
    case playbackFailed
    case seekingFailed
    case volumeControlFailed
    case applicationNotFound
    
    public var errorDescription: String? {
        switch self {
        case .unsupportedFeature(let feature):
            return "不支持的功能: \(feature)"
        case .mediaLoadFailed:
            return "媒体加载失败"
        case .playbackFailed:
            return "播放失败"
        case .seekingFailed:
            return "快进/快退失败"
        case .volumeControlFailed:
            return "音量控制失败"
        case .applicationNotFound:
            return "播放器应用未找到"
        }
    }
}
