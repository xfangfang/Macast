import Foundation
import Network

// MARK: - ChromecastRendererProtocol Protocol

/// Chromecast渲染器插件的协议
public protocol ChromecastRendererProtocol: MacastPlugin {
    
    // MARK: - Basic Properties
    
    /// 渲染器的友好名称
    var friendlyName: String { get set }
    
    /// 渲染器的设备ID
    var deviceID: String { get }
    
    /// 渲染器的型号名称
    var modelName: String { get }
    
    /// 渲染器的制造商
    var manufacturer: String { get }
    
    /// 渲染器的当前状态
    var playbackState: ChromecastPlaybackState { get }
    
    /// 当前播放的媒体信息
    var currentMediaInfo: ChromecastMediaInfo? { get }
    
    /// 音量信息
    var volumeInfo: ChromecastVolumeInfo { get }
    
    /// 支持的播放速率
    var supportedPlaybackRates: [Double] { get }
    
    /// 支持的媒体格式
    var supportedMediaFormats: [String] { get }
    
    /// Chromecast功能支持
    var chromecastFeatures: [ChromecastFeature] { get }
    
    // MARK: - Playback Control Methods
    
    /// 加载媒体
    /// - Parameter mediaURL: 媒体URL
    /// - Parameter position: 开始播放的位置（秒）
    /// - Parameter metadata: 媒体元数据
    /// - Parameter autoplay: 是否自动播放
    func loadMedia(mediaURL: URL, position: Double, metadata: [String: Any]?, autoplay: Bool) throws
    
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
    /// - Parameter volume: 音量值（0.0-1.0）
    func setVolume(volume: Double) throws
    
    /// 增加音量
    /// - Parameter delta: 增加的音量值（0.0-1.0）
    func increaseVolume(delta: Double) throws
    
    /// 减少音量
    /// - Parameter delta: 减少的音量值（0.0-1.0）
    func decreaseVolume(delta: Double) throws
    
    /// 设置静音状态
    /// - Parameter muted: 静音状态
    func setMuted(muted: Bool) throws
    
    // MARK: - Chromecast Specific Methods
    
    /// 启动应用
    /// - Parameter appID: 应用ID
    func launchApp(appID: String) throws
    
    /// 关闭应用
    func closeApp() throws
    
    /// 获取当前运行的应用
    /// - Returns: 当前应用ID
    func getCurrentApp() -> String?
    
    /// 设置播放模式
    /// - Parameter mode: 播放模式
    func setPlayMode(_ mode: ChromecastPlayMode) throws
    
    /// 设置字幕
    /// - Parameter subtitleURL: 字幕URL
    /// - Parameter language: 字幕语言
    func setSubtitle(_ subtitleURL: URL?, language: String?) throws
    
    /// 禁用字幕
    func disableSubtitle() throws
    
    /// 设置音频轨道
    /// - Parameter trackID: 音频轨道ID
    func setAudioTrack(_ trackID: Int) throws
    
    /// 设置视频轨道
    /// - Parameter trackID: 视频轨道ID
    func setVideoTrack(_ trackID: Int) throws
    
    /// 设置播放方向
    /// - Parameter direction: 播放方向
    func setPlaybackDirection(_ direction: ChromecastPlaybackDirection) throws
    
    /// 设置画面缩放模式
    /// - Parameter mode: 缩放模式
    func setScalingMode(_ mode: ChromecastScalingMode) throws
    
    /// 开始屏幕镜像
    func startMirroring() throws
    
    /// 停止屏幕镜像
    func stopMirroring() throws
    
    /// 获取设备状态
    /// - Returns: 设备状态信息
    func getDeviceStatus() -> ChromecastDeviceStatus
    
    // MARK: - Event Handling
    
    /// 注册渲染器事件监听器
    /// - Parameter listener: 事件监听器
    func registerEventListener(_ listener: ChromecastRendererEventListener)
    
    /// 移除渲染器事件监听器
    /// - Parameter listener: 事件监听器
    func removeEventListener(_ listener: ChromecastRendererEventListener)
    
    /// 移除所有渲染器事件监听器
    func removeAllEventListeners()
}

// MARK: - ChromecastPlaybackState

/// Chromecast播放状态枚举
public enum ChromecastPlaybackState: String {
    case idle = "IDLE"
    case playing = "PLAYING"
    case paused = "PAUSED"
    case buffering = "BUFFERING"
    case loading = "LOADING"
    case error = "ERROR"
    case unknown = "UNKNOWN"
}

// MARK: - ChromecastMediaInfo

/// Chromecast媒体信息结构体
public struct ChromecastMediaInfo {
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
    var mediaType: ChromecastMediaType
    
    /// 媒体格式
    var format: String?
    
    /// 媒体大小（字节）
    var size: Int64?
    
    /// 媒体元数据
    var metadata: [String: Any]?
    
    /// 媒体内容类型
    var contentType: String
    
    /// 媒体流类型
    var streamType: ChromecastStreamType
}

// MARK: - ChromecastStreamType

/// Chromecast流类型枚举
public enum ChromecastStreamType: String {
    case none = "NONE"
    case buffered = "BUFFERED"
    case live = "LIVE"
    case other = "OTHER"
}

// MARK: - ChromecastVolumeInfo

/// Chromecast音量信息结构体
public struct ChromecastVolumeInfo {
    /// 当前音量（0.0-1.0）
    var currentVolume: Double
    
    /// 是否静音
    var isMuted: Bool
    
    /// 音量是否可控制
    var isVolumeControlAvailable: Bool
}

// MARK: - ChromecastFeature

/// Chromecast功能枚举
public enum ChromecastFeature: String {
    case audio = "audio"
    case video = "video"
    case photo = "photo"
    case screenMirroring = "screenMirroring"
    case subtitles = "subtitles"
    case audioTracks = "audioTracks"
    case videoTracks = "videoTracks"
    case playbackRates = "playbackRates"
    case scalingModes = "scalingModes"
    case timeSeek = "timeSeek"
    case playModes = "playModes"
    case appControl = "appControl"
}

// MARK: - ChromecastMediaType

/// Chromecast媒体类型枚举
public enum ChromecastMediaType {
    case audio
    case video
    case photo
    case screen
    case application
}

// MARK: - ChromecastPlayMode

/// Chromecast播放模式枚举
public enum ChromecastPlayMode: String {
    case normal = "NORMAL"
    case repeatOne = "REPEAT_ONE"
    case repeatAll = "REPEAT_ALL"
    case shuffle = "SHUFFLE"
    case linear = "LINEAR"
}

// MARK: - ChromecastPlaybackDirection

/// Chromecast播放方向枚举
public enum ChromecastPlaybackDirection {
    case forward
    case backward
}

// MARK: - ChromecastScalingMode

/// Chromecast画面缩放模式枚举
public enum ChromecastScalingMode: String {
    case fit = "FIT"
    case fill = "FILL"
    case stretch = "STRETCH"
    case original = "ORIGINAL"
    case zoom = "ZOOM"
}

// MARK: - ChromecastDeviceStatus

/// Chromecast设备状态结构体
public struct ChromecastDeviceStatus {
    /// 设备名称
    var deviceName: String
    
    /// 设备ID
    var deviceID: String
    
    /// 设备型号
    var deviceModel: String
    
    /// 设备制造商
    var deviceManufacturer: String
    
    /// 固件版本
    var firmwareVersion: String
    
    /// IP地址
    var ipAddress: String
    
    /// 端口号
    var port: Int
    
    /// 设备类型
    var deviceType: String
    
    /// 设备状态
    var deviceStatus: String
}

// MARK: - ChromecastRendererEventListener

/// Chromecast渲染器事件监听器协议
public protocol ChromecastRendererEventListener: AnyObject {
    /// 播放状态变化事件
    func onPlaybackStateChanged(state: ChromecastPlaybackState)
    
    /// 媒体信息变化事件
    func onMediaInfoChanged(info: ChromecastMediaInfo?)
    
    /// 音量变化事件
    func onVolumeChanged(info: ChromecastVolumeInfo)
    
    /// 播放位置变化事件
    func onPositionChanged(position: Double, duration: Double)
    
    /// 渲染器错误事件
    func onError(error: ChromecastRendererError)
    
    /// 媒体加载完成事件
    func onMediaLoaded()
    
    /// 媒体播放完成事件
    func onMediaEnded()
    
    /// 应用启动事件
    func onAppLaunched(appID: String)
    
    /// 应用关闭事件
    func onAppClosed(appID: String)
    
    /// 设备状态变化事件
    func onDeviceStatusChanged(status: ChromecastDeviceStatus)
    
    /// 屏幕镜像开始事件
    func onMirroringStarted()
    
    /// 屏幕镜像停止事件
    func onMirroringStopped()
}

// MARK: - ChromecastRendererError

/// Chromecast渲染器错误枚举
public enum ChromecastRendererError: Error {
    case applicationNotFound
    case applicationNotRunning
    case invalidMediaURL
    case unsupportedMediaType
    case unsupportedFeature
    case playbackFailed
    case connectionLost
    case timeout
    case internalError
    case appLaunchFailed
    case appCloseFailed
    case mirroringFailed
    
    var localizedDescription: String {
        switch self {
        case .applicationNotFound:
            return "Chromecast渲染器应用程序未找到"
        case .applicationNotRunning:
            return "Chromecast渲染器应用程序未运行"
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
        case .appLaunchFailed:
            return "应用启动失败"
        case .appCloseFailed:
            return "应用关闭失败"
        case .mirroringFailed:
            return "屏幕镜像失败"
        }
    }
}
