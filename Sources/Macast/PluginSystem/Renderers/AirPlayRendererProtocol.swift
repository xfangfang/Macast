import Foundation
import Network

// MARK: - AirPlayRendererProtocol Protocol

/// AirPlay渲染器插件的协议
public protocol AirPlayRendererProtocol: MacastPlugin {
    
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
    var playbackState: AirPlayPlaybackState { get }
    
    /// 当前播放的媒体信息
    var currentMediaInfo: AirPlayMediaInfo? { get }
    
    /// 音量信息
    var volumeInfo: AirPlayVolumeInfo { get }
    
    /// 支持的播放速率
    var supportedPlaybackRates: [Double] { get }
    
    /// 支持的媒体格式
    var supportedMediaFormats: [String] { get }
    
    /// AirPlay 功能支持
    var airPlayFeatures: [AirPlayFeature] { get }
    
    // MARK: - Playback Control Methods
    
    /// 加载媒体
    /// - Parameter mediaURL: 媒体URL
    /// - Parameter position: 开始播放的位置（秒）
    /// - Parameter metadata: 媒体元数据
    func loadMedia(mediaURL: URL, position: Double, metadata: [String: Any]?) throws
    
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
    
    // MARK: - AirPlay Specific Methods
    
    /// 设置播放模式
    /// - Parameter mode: 播放模式
    func setPlayMode(_ mode: AirPlayPlayMode) throws
    
    /// 设置字幕
    /// - Parameter subtitleURL: 字幕URL
    func setSubtitle(_ subtitleURL: URL?) throws
    
    /// 设置音频轨道
    /// - Parameter trackIndex: 音频轨道索引
    func setAudioTrack(_ trackIndex: Int) throws
    
    /// 设置视频轨道
    /// - Parameter trackIndex: 视频轨道索引
    func setVideoTrack(_ trackIndex: Int) throws
    
    /// 设置播放方向
    /// - Parameter direction: 播放方向
    func setPlaybackDirection(_ direction: AirPlayPlaybackDirection) throws
    
    /// 设置画面缩放模式
    /// - Parameter mode: 缩放模式
    func setScalingMode(_ mode: AirPlayScalingMode) throws
    
    // MARK: - Event Handling
    
    /// 注册渲染器事件监听器
    /// - Parameter listener: 事件监听器
    func registerEventListener(_ listener: AirPlayRendererEventListener)
    
    /// 移除渲染器事件监听器
    /// - Parameter listener: 事件监听器
    func removeEventListener(_ listener: AirPlayRendererEventListener)
    
    /// 移除所有渲染器事件监听器
    func removeAllEventListeners()
}

// MARK: - AirPlayPlaybackState

/// AirPlay播放状态枚举
public enum AirPlayPlaybackState: String {
    case stopped = "STOPPED"
    case playing = "PLAYING"
    case paused = "PAUSED"
    case buffering = "BUFFERING"
    case loading = "LOADING"
    case error = "ERROR"
    case unknown = "UNKNOWN"
}

// MARK: - AirPlayMediaInfo

/// AirPlay媒体信息结构体
public struct AirPlayMediaInfo {
    /// 媒体时长（秒）
    var duration: Double
    
    /// 媒体URL
    var mediaURL: URL
    
    /// 媒体标题
    var title: String?
    
    /// 媒体艺术家
    var artist: String?
    
    /// 媒体专辑
    var album: String?
    
    /// 媒体类型
    var mediaType: AirPlayMediaType
    
    /// 媒体格式
    var format: String?
    
    /// 媒体大小（字节）
    var size: Int64?
    
    /// 媒体元数据
    var metadata: [String: Any]?
}

// MARK: - AirPlayVolumeInfo

/// AirPlay音量信息结构体
public struct AirPlayVolumeInfo {
    /// 当前音量（0-100）
    var currentVolume: Int
    
    /// 是否静音
    var isMuted: Bool
    
    /// 音量是否可控制
    var isVolumeControlAvailable: Bool
}

// MARK: - AirPlayFeature

/// AirPlay功能枚举
public enum AirPlayFeature: String {
    case audio = "audio"
    case video = "video"
    case photo = "photo"
    case slideshow = "slideshow"
    case screen = "screen"
    case subtitles = "subtitles"
    case audioTracks = "audioTracks"
    case videoTracks = "videoTracks"
    case playbackRates = "playbackRates"
    case scalingModes = "scalingModes"
    case timeSeek = "timeSeek"
    case playModes = "playModes"
}

// MARK: - AirPlayMediaType

/// AirPlay媒体类型枚举
public enum AirPlayMediaType {
    case audio
    case video
    case photo
    case screen
}

// MARK: - AirPlayPlayMode

/// AirPlay播放模式枚举
public enum AirPlayPlayMode: String {
    case normal = "NORMAL"
    case repeatOne = "REPEAT_ONE"
    case repeatAll = "REPEAT_ALL"
    case shuffle = "SHUFFLE"
}

// MARK: - AirPlayPlaybackDirection

/// AirPlay播放方向枚举
public enum AirPlayPlaybackDirection {
    case forward
    case backward
}

// MARK: - AirPlayScalingMode

/// AirPlay画面缩放模式枚举
public enum AirPlayScalingMode: String {
    case fit = "FIT"
    case fill = "FILL"
    case stretch = "STRETCH"
    case original = "ORIGINAL"
}

// MARK: - AirPlayRendererEventListener

/// AirPlay渲染器事件监听器协议
public protocol AirPlayRendererEventListener: AnyObject {
    /// 播放状态变化事件
    func onPlaybackStateChanged(state: AirPlayPlaybackState)
    
    /// 媒体信息变化事件
    func onMediaInfoChanged(info: AirPlayMediaInfo?)
    
    /// 音量变化事件
    func onVolumeChanged(info: AirPlayVolumeInfo)
    
    /// 播放位置变化事件
    func onPositionChanged(position: Double, duration: Double)
    
    /// 渲染器错误事件
    func onError(error: AirPlayRendererError)
    
    /// 媒体加载完成事件
    func onMediaLoaded()
    
    /// 媒体播放完成事件
    func onMediaEnded()
}

// MARK: - AirPlayRendererError

/// AirPlay渲染器错误枚举
public enum AirPlayRendererError: Error {
    case applicationNotFound
    case applicationNotRunning
    case invalidMediaURL
    case unsupportedMediaType
    case unsupportedFeature
    case playbackFailed
    case connectionLost
    case timeout
    case internalError
    
    var localizedDescription: String {
        switch self {
        case .applicationNotFound:
            return "AirPlay渲染器应用程序未找到"
        case .applicationNotRunning:
            return "AirPlay渲染器应用程序未运行"
        case .invalidMediaURL:
            return "无效的媒体URL"
        case .unsupportedMediaType:
            return "不支持的媒体类型"
        case .unsupportedFeature:
            return "不支持的功能"
        case .playbackFailed:
            return "媒体播放失败"
        case .connectionLost:
            return "连接已断开"
        case .timeout:
            return "操作超时"
        case .internalError:
            return "内部错误"
        }
    }
}
