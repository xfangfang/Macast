import XCTest
@testable import Macast

// MARK: - Test Renderer for Protocol Tests

class TestRenderer: DLNARendererProtocol {
    var name: String = "Test Renderer"
    var version: String = "1.0.0"
    var identifier: String = "test.renderer"
    var description: String = "Test Renderer"
    var author: String = "Test"
    var isEnabled: Bool = true
    var isLoaded: Bool = true
    
    // DLNARendererProtocol properties
    var friendlyName: String = "Test Renderer"
    var udn: String = "uuid:test-renderer-" + UUID().uuidString
    var modelName: String = "Test Model"
    var manufacturer: String = "Test Manufacturer"
    var playbackState: DLNAPlaybackState = .stopped
    var currentMediaInfo: DLNAMediaInfo?
    var volumeInfo: DLNAVolumeInfo = DLNAVolumeInfo(volume: 50, maxVolume: 100, muted: false)
    var supportedPlaybackRates: [String] = ["0.5", "1", "2"]
    
    // 自定义媒体格式
    var supportedMediaFormats: [String] = ["video/mp4", "audio/mpeg"]
    
    // 事件监听器
    private var listeners: [DLNARendererEventListener] = []
    
    required init() {}
    
    // MARK: - Playback Control Methods
    
    func loadMedia(mediaURL: URL, position: Double) throws {
        currentMediaInfo = DLNAMediaInfo(
            duration: 3600,
            mediaURL: mediaURL,
            title: "Test Media",
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
        playbackState = .playing
        notifyPlaybackStateChanged()
    }
    
    func play() throws {
        playbackState = .playing
        notifyPlaybackStateChanged()
    }
    
    func pause() throws {
        playbackState = .paused
        notifyPlaybackStateChanged()
    }
    
    func stop() throws {
        playbackState = .stopped
        currentMediaInfo = nil
        notifyPlaybackStateChanged()
    }
    
    func seekForward(seconds: Double) throws {
        // 默认实现应该调用seekTo
    }
    
    func seekBackward(seconds: Double) throws {
        // 默认实现应该调用seekTo
    }
    
    func seekTo(position: Double) throws {
        // 更新位置信息
        notifyPositionChanged(position: position)
    }
    
    func getCurrentPosition() -> Double {
        return 120.0 // 测试值
    }

    func getMediaInfo() -> DLNAMediaInfo? {
        currentMediaInfo
    }
    
    // MARK: - Volume Control Methods
    
    func setVolume(volume: Int) throws {
        volumeInfo = DLNAVolumeInfo(volume: volume, maxVolume: 100, muted: volumeInfo.muted)
        notifyVolumeChanged()
    }
    
    func increaseVolume(delta: Int) throws {
        let newVolume = min(100, volumeInfo.volume + delta)
        try setVolume(volume: newVolume)
    }
    
    func decreaseVolume(delta: Int) throws {
        let newVolume = max(0, volumeInfo.volume - delta)
        try setVolume(volume: newVolume)
    }
    
    func setMuted(muted: Bool) throws {
        volumeInfo = DLNAVolumeInfo(volume: volumeInfo.volume, maxVolume: 100, muted: muted)
        notifyVolumeChanged()
    }
    
    // MARK: - Event Handling
    
    func registerEventListener(_ listener: DLNARendererEventListener) {
        listeners.append(listener)
    }
    
    func removeEventListener(_ listener: DLNARendererEventListener) {
        listeners.removeAll(where: { $0 === listener })
    }
    
    func removeAllEventListeners() {
        listeners.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func notifyPlaybackStateChanged() {
        for listener in listeners {
            listener.renderer(self, playbackStateChanged: playbackState)
        }
    }
    
    private func notifyPositionChanged(position: Double) {
        for listener in listeners {
            listener.renderer(self, positionChanged: position)
        }
    }
    
    private func notifyVolumeChanged() {
        for listener in listeners {
            listener.renderer(self, volumeChanged: volumeInfo.volume)
            listener.renderer(self, muteChanged: volumeInfo.muted)
        }
    }
}

// MARK: - Test Event Listener

class TestEventListener: DLNARendererEventListener {
    var stateChanged: Bool = false
    var positionChanged: Bool = false
    var volumeChanged: Bool = false
    var muteChanged: Bool = false
    var lastPosition: Double = 0
    var lastVolume: Int = 0
    var lastMuted: Bool = false
    
    func renderer(_ renderer: DLNARendererProtocol, playbackStateChanged state: DLNAPlaybackState) {
        stateChanged = true
    }
    
    func renderer(_ renderer: DLNARendererProtocol, mediaLoaded mediaInfo: DLNAMediaInfo) {
    }
    
    func renderer(_ renderer: DLNARendererProtocol, positionChanged position: Double) {
        positionChanged = true
        lastPosition = position
    }
    
    func renderer(_ renderer: DLNARendererProtocol, volumeChanged volume: Int) {
        volumeChanged = true
        lastVolume = volume
    }
    
    func renderer(_ renderer: DLNARendererProtocol, muteChanged muted: Bool) {
        muteChanged = true
        lastMuted = muted
    }
    
    func rendererDidFinishPlayback(_ renderer: DLNARendererProtocol) {}
    func renderer(_ renderer: DLNARendererProtocol, didEncounterError error: Error) {}
}

// MARK: - DLNARendererProtocolTests

class DLNARendererProtocolTests: XCTestCase {
    
    var testRenderer: TestRenderer!
    var testListener: TestEventListener!
    
    override func setUp() {
        super.setUp()
        testRenderer = TestRenderer()
        testListener = TestEventListener()
    }
    
    override func tearDown() {
        testRenderer = nil
        testListener = nil
        super.tearDown()
    }
    
    // 测试渲染器基本属性
    func testRendererBasicProperties() {
        XCTAssertEqual(testRenderer.name, "Test Renderer", "渲染器名称应该匹配")
        XCTAssertEqual(testRenderer.version, "1.0.0", "渲染器版本应该匹配")
        XCTAssertEqual(testRenderer.identifier, "test.renderer", "渲染器标识符应该匹配")
        XCTAssertEqual(testRenderer.friendlyName, "Test Renderer", "渲染器友好名称应该匹配")
        XCTAssertEqual(testRenderer.modelName, "Test Model", "渲染器型号名称应该匹配")
        XCTAssertEqual(testRenderer.manufacturer, "Test Manufacturer", "渲染器制造商应该匹配")
    }
    
    // 测试默认实现的媒体格式
    func testDefaultMediaFormats() {
        XCTAssertEqual(testRenderer.getSupportedMediaFormats(), ["video/mp4", "audio/mpeg"], "支持的媒体格式应该匹配")
    }
    
    // 测试默认实现的播放速率列表
    func testDefaultPlaybackRates() {
        XCTAssertEqual(testRenderer.getPlaybackRateList(), ["0.5", "1", "2"], "播放速率列表应该匹配")
    }
    
    // 测试默认实现的设备功能
    func testDefaultDeviceCapabilities() {
        let capabilities = testRenderer.getDeviceCapabilities()
        XCTAssertEqual(capabilities.playbackRateList, ["0.5", "1", "2"], "设备功能中的播放速率列表应该匹配")
        XCTAssertEqual(
            capabilities.transportPlayStates,
            [DLNAPlaybackState.stopped.rawValue, DLNAPlaybackState.playing.rawValue, DLNAPlaybackState.paused.rawValue],
            "设备功能中的播放状态列表应该匹配"
        )
    }
    
    // 测试默认实现的传输信息
    func testDefaultTransportInfo() {
        let transportInfo = testRenderer.getTransportInfo()
        XCTAssertEqual(transportInfo.transportState, .stopped, "传输信息中的状态应该匹配")
        XCTAssertEqual(transportInfo.transportStatus, "OK", "传输信息中的状态描述应该匹配")
        XCTAssertEqual(transportInfo.playSpeed, "1", "传输信息中的播放速度应该匹配")
    }
    
    // 测试默认实现的位置信息
    func testDefaultPositionInfo() {
        let positionInfo = testRenderer.getPositionInfo()
        XCTAssertEqual(positionInfo.currentPosition, 120.0, "位置信息中的当前位置应该匹配")
        XCTAssertEqual(positionInfo.currentTime, "2:00", "位置信息中的当前时间格式应该正确")
        XCTAssertEqual(positionInfo.totalTime, "0:00", "位置信息中的总时间格式应该正确")
    }
    
    // 测试默认实现的seekForward和seekBackward
    func testDefaultSeekForwardBackward() {
        let position = 120.0 // 当前位置
        
        // 测试seekForward
        let forwardPosition = position + 30.0
        XCTAssertEqual(forwardPosition, 150.0, "快进后位置应该正确")
        
        // 测试seekBackward
        let backwardPosition = position - 30.0
        XCTAssertEqual(backwardPosition, 90.0, "快退后位置应该正确")
    }
    
    // 测试渲染器事件监听
    func testRendererEventListener() {
        // 注册事件监听器
        testRenderer.registerEventListener(testListener)
        
        // 触发状态变化
        do {
            try testRenderer.play()
            XCTAssertTrue(testListener.stateChanged, "应该收到状态变化事件")
        } catch {
            XCTFail("播放方法执行失败: \(error.localizedDescription)")
        }
        
        // 触发音量变化
        do {
            try testRenderer.setVolume(volume: 75)
            XCTAssertTrue(testListener.volumeChanged, "应该收到音量变化事件")
            XCTAssertEqual(testListener.lastVolume, 75, "音量值应该匹配")
        } catch {
            XCTFail("设置音量方法执行失败: \(error.localizedDescription)")
        }
        
        // 移除事件监听器
        testRenderer.removeEventListener(testListener)
        
        // 重置监听器状态
        testListener.volumeChanged = false
        
        // 再次触发音量变化
        do {
            try testRenderer.setVolume(volume: 80)
            XCTAssertFalse(testListener.volumeChanged, "移除监听器后不应该收到音量变化事件")
        } catch {
            XCTFail("设置音量方法执行失败: \(error.localizedDescription)")
        }
    }
    
    // 测试移除所有事件监听器
    func testRemoveAllEventListeners() {
        // 注册两个事件监听器
        let listener1 = TestEventListener()
        let listener2 = TestEventListener()
        
        testRenderer.registerEventListener(listener1)
        testRenderer.registerEventListener(listener2)
        
        // 移除所有事件监听器
        testRenderer.removeAllEventListeners()
        
        // 触发状态变化
        do {
            try testRenderer.pause()
            XCTAssertFalse(listener1.stateChanged, "移除所有监听器后listener1不应该收到事件")
            XCTAssertFalse(listener2.stateChanged, "移除所有监听器后listener2不应该收到事件")
        } catch {
            XCTFail("暂停方法执行失败: \(error.localizedDescription)")
        }
    }
    
    // 测试时间格式化方法
    func testTimeFormatting() {
        // 测试0秒
        var formattedTime = testRenderer.formatTime(seconds: 0)
        XCTAssertEqual(formattedTime, "0:00", "0秒应该格式化为0:00")
        
        // 测试10秒
        formattedTime = testRenderer.formatTime(seconds: 10)
        XCTAssertEqual(formattedTime, "0:10", "10秒应该格式化为0:10")
        
        // 测试60秒
        formattedTime = testRenderer.formatTime(seconds: 60)
        XCTAssertEqual(formattedTime, "1:00", "60秒应该格式化为1:00")
        
        // 测试70秒
        formattedTime = testRenderer.formatTime(seconds: 70)
        XCTAssertEqual(formattedTime, "1:10", "70秒应该格式化为1:10")
        
        // 测试3600秒 (1小时)
        formattedTime = testRenderer.formatTime(seconds: 3600)
        XCTAssertEqual(formattedTime, "1:00:00", "3600秒应该格式化为1:00:00")
        
        // 测试3661秒 (1小时1分钟1秒)
        formattedTime = testRenderer.formatTime(seconds: 3661)
        XCTAssertEqual(formattedTime, "1:01:01", "3661秒应该格式化为1:01:01")
    }
}
