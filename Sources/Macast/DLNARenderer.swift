import Foundation
import Network

// DLNA渲染器类
class DLNAMediaRenderer: NSObject, MPVControllerDelegate {
    
    // MARK: - Properties
    
    // 播放器控制器
    private var mpvController: MPVController
    
    // 连接状态
    var isConnected: Bool = false
    
    // 当前媒体URL
    var currentMediaURL: URL?
    
    // 渲染器委托
    weak var delegate: DLNAMediaRendererDelegate?
    
    // MARK: - Initialization
    
    override init() {
        // 初始化播放器控制器
        mpvController = MPVController()
        
        super.init()
        
        // 设置播放器委托
        mpvController.delegate = self
        
        // 注册DLNA服务
        registerDLNAServices()
    }
    
    deinit {
        // 停止所有服务
        stopAllServices()
    }
    
    // MARK: - Public Methods
    
    // 启动渲染器
    func start() {
        // 这里可以启动任何需要的服务
        isConnected = true
        delegate?.rendererDidConnect(self)
        print("DLNA渲染器已启动")
    }
    
    // 停止渲染器
    func stop() {
        stopAllServices()
        isConnected = false
        delegate?.rendererDidDisconnect(self)
        print("DLNA渲染器已停止")
    }
    
    // 连接到媒体服务器
    func connect(to mediaServerURL: URL) {
        // 这里可以实现与媒体服务器的连接逻辑
        isConnected = true
        delegate?.rendererDidConnect(self)
        print("已连接到媒体服务器: \(mediaServerURL)")
    }
    
    // 断开连接
    func disconnect() {
        // 停止播放
        mpvController.stop()
        
        // 更新连接状态
        isConnected = false
        delegate?.rendererDidDisconnect(self)
        print("已断开连接")
    }
    
    // 播放媒体
    func play(mediaURL: URL) {
        // 加载并播放媒体
        mpvController.load(url: mediaURL)
        mpvController.play()
        
        // 更新当前媒体URL
        currentMediaURL = mediaURL
        
        print("播放媒体: \(mediaURL)")
    }
    
    // 暂停播放
    func pause() {
        mpvController.pause()
    }
    
    // 停止播放
    func stopPlayback() {
        mpvController.stop()
    }
    
    // 快进/快退
    func seek(seconds: Double) {
        mpvController.seek(seconds: seconds)
    }
    
    // 设置音量
    func setVolume(volume: Int) {
        mpvController.setVolume(volume: volume)
    }
    
    // 设置静音
    func setMute(muted: Bool) {
        mpvController.setMute(muted: muted)
    }
    
    // MARK: - Private Methods
    
    // 注册DLNA服务
    private func registerDLNAServices() {
        // 确保DLNAServiceManager已经初始化
        _ = DLNAServiceManager.shared
        
        print("DLNA服务已注册")
    }
    
    // 停止所有服务
    private func stopAllServices() {
        // 停止播放器
        mpvController.stop()
        
        print("所有服务已停止")
    }
    
    // MARK: - MPVControllerDelegate Methods
    
    // 播放器加载完成
    func playerDidLoad(controller: MPVController, url: URL) {
        delegate?.rendererDidLoadMedia(self, url: url)
    }
    
    // 开始播放
    func playerDidPlay(controller: MPVController) {
        // 更新AVTransport服务状态
        if let avTransportService = DLNAServiceManager.shared.getService(type: .avTransport) as? AVTransportService {
            avTransportService.currentTransportState = "PLAYING"
            avTransportService.currentTransportStatus = "OK"
        }
        
        delegate?.rendererDidStartPlayback(self)
    }
    
    // 暂停播放
    func playerDidPause(controller: MPVController) {
        // 更新AVTransport服务状态
        if let avTransportService = DLNAServiceManager.shared.getService(type: .avTransport) as? AVTransportService {
            avTransportService.currentTransportState = "PAUSED_PLAYBACK"
            avTransportService.currentTransportStatus = "OK"
        }
        
        delegate?.rendererDidPausePlayback(self)
    }
    
    // 停止播放
    func playerDidStop(controller: MPVController) {
        // 更新AVTransport服务状态
        if let avTransportService = DLNAServiceManager.shared.getService(type: .avTransport) as? AVTransportService {
            avTransportService.currentTransportState = "STOPPED"
            avTransportService.currentTransportStatus = "OK"
        }
        
        delegate?.rendererDidStopPlayback(self)
    }
    
    // 播放结束
    func playerDidFinish(controller: MPVController) {
        // 更新AVTransport服务状态
        if let avTransportService = DLNAServiceManager.shared.getService(type: .avTransport) as? AVTransportService {
            avTransportService.currentTransportState = "STOPPED"
            avTransportService.currentTransportStatus = "OK"
        }
        
        delegate?.rendererDidFinishPlayback(self)
    }
    
    // 快进/快退
    func playerDidSeek(controller: MPVController, time: Double) {
        // 更新AVTransport服务状态
        if let avTransportService = DLNAServiceManager.shared.getService(type: .avTransport) as? AVTransportService {
            avTransportService.currentPosition = formatTime(seconds: time)
        }
        
        delegate?.rendererDidSeek(self, time: time)
    }
    
    // 音量变化
    func playerVolumeDidChange(controller: MPVController, volume: Int) {
        // 更新RenderingControl服务状态
        if let renderingControlService = DLNAServiceManager.shared.getService(type: .renderingControl) as? RenderingControlService {
            renderingControlService.volume["Master"] = volume
        }
        
        delegate?.rendererVolumeDidChange(self, volume: volume)
    }
    
    // 静音状态变化
    func playerMuteDidChange(controller: MPVController, muted: Bool) {
        // 更新RenderingControl服务状态
        if let renderingControlService = DLNAServiceManager.shared.getService(type: .renderingControl) as? RenderingControlService {
            renderingControlService.mute["Master"] = muted
        }
        
        delegate?.rendererMuteDidChange(self, muted: muted)
    }
    
    // 播放错误
    func playerDidError(controller: MPVController, error: Error) {
        // 更新AVTransport服务状态
        if let avTransportService = DLNAServiceManager.shared.getService(type: .avTransport) as? AVTransportService {
            avTransportService.currentTransportState = "STOPPED"
            avTransportService.currentTransportStatus = "ERROR_OCCURRED"
        }
        
        delegate?.rendererDidError(self, error: error)
    }
    
    // MARK: - Helper Methods
    
    // 格式化时间（秒 -> HH:MM:SS）
    private func formatTime(seconds: Double) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
    
    // 解析时间（HH:MM:SS -> 秒）
    private func parseTime(timeString: String) -> Double {
        let components = timeString.split(separator: ":").map { Double($0) ?? 0.0 }
        
        switch components.count {
        case 3: // HH:MM:SS
            return components[0] * 3600 + components[1] * 60 + components[2]
        case 2: // MM:SS
            return components[0] * 60 + components[1]
        case 1: // SS
            return components[0]
        default:
            return 0.0
        }
    }
}

// MARK: - DLNARendererDelegate Protocol

protocol DLNAMediaRendererDelegate: AnyObject {
    // 渲染器连接成功
    func rendererDidConnect(_ renderer: DLNAMediaRenderer)
    
    // 渲染器断开连接
    func rendererDidDisconnect(_ renderer: DLNAMediaRenderer)
    
    // 渲染器加载媒体完成
    func rendererDidLoadMedia(_ renderer: DLNAMediaRenderer, url: URL)
    
    // 渲染器开始播放
    func rendererDidStartPlayback(_ renderer: DLNAMediaRenderer)
    
    // 渲染器暂停播放
    func rendererDidPausePlayback(_ renderer: DLNAMediaRenderer)
    
    // 渲染器停止播放
    func rendererDidStopPlayback(_ renderer: DLNAMediaRenderer)
    
    // 渲染器播放结束
    func rendererDidFinishPlayback(_ renderer: DLNAMediaRenderer)
    
    // 渲染器快进/快退
    func rendererDidSeek(_ renderer: DLNAMediaRenderer, time: Double)
    
    // 渲染器音量变化
    func rendererVolumeDidChange(_ renderer: DLNAMediaRenderer, volume: Int)
    
    // 渲染器静音状态变化
    func rendererMuteDidChange(_ renderer: DLNAMediaRenderer, muted: Bool)
    
    // 渲染器错误
    func rendererDidError(_ renderer: DLNAMediaRenderer, error: Error)
}

// MARK: - DLNARendererDelegate Default Implementation

extension DLNAMediaRendererDelegate {
    func rendererDidConnect(_ renderer: DLNAMediaRenderer) {}
    func rendererDidDisconnect(_ renderer: DLNAMediaRenderer) {}
    func rendererDidLoadMedia(_ renderer: DLNAMediaRenderer, url: URL) {}
    func rendererDidStartPlayback(_ renderer: DLNAMediaRenderer) {}
    func rendererDidPausePlayback(_ renderer: DLNAMediaRenderer) {}
    func rendererDidStopPlayback(_ renderer: DLNAMediaRenderer) {}
    func rendererDidFinishPlayback(_ renderer: DLNAMediaRenderer) {}
    func rendererDidSeek(_ renderer: DLNAMediaRenderer, time: Double) {}
    func rendererVolumeDidChange(_ renderer: DLNAMediaRenderer, volume: Int) {}
    func rendererMuteDidChange(_ renderer: DLNAMediaRenderer, muted: Bool) {}
    func rendererDidError(_ renderer: DLNAMediaRenderer, error: Error) {}
}
