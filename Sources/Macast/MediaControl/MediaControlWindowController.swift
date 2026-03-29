import AppKit

/// 媒体播放控制窗口控制器
class MediaControlWindowController: NSWindowController {
    static let shared = MediaControlWindowController()
    
    // MARK: - UI Components
    
    private let contentView = NSView()
    private let mediaTitleLabel = NSTextField()
    private let currentTimeLabel = NSTextField()
    private let durationLabel = NSTextField()
    private let progressSlider = NSSlider()
    private let playPauseButton = NSButton()
    private let stopButton = NSButton()
    private let forwardButton = NSButton()
    private let backwardButton = NSButton()
    private let volumeButton = NSButton()
    private let volumeSlider = NSSlider()
    
    // MARK: - Private Properties
    
    /// 当前的渲染器
    private var currentRenderer: DLNARendererProtocol?
    
    /// 播放位置更新计时器
    private var positionUpdateTimer: Timer?
    
    // MARK: - Initialization
    
    override init(window: NSWindow?) {
        super.init(window: window)
        setupWindow()
        setupUI()
        setupEventListeners()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWindow()
        setupUI()
        setupEventListeners()
    }
    
    // MARK: - Window Setup
    
    private func setupWindow() {
        // 创建窗口
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 120),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // 设置窗口属性
        window.title = "Macast - 媒体控制"
        window.center()
        window.isReleasedWhenClosed = false
        window.contentView = contentView
        window.level = .floating
        
        self.window = window
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // 配置ContentView
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        // 配置媒体标题标签
        mediaTitleLabel.stringValue = "无媒体播放"
        mediaTitleLabel.font = NSFont.systemFont(ofSize: 14.0, weight: .semibold)
        mediaTitleLabel.isEditable = false
        mediaTitleLabel.isSelectable = false
        mediaTitleLabel.drawsBackground = false
        mediaTitleLabel.alignment = .center
        mediaTitleLabel.cell?.wraps = true
        mediaTitleLabel.cell?.isScrollable = false
        
        // 配置当前时间标签
        currentTimeLabel.stringValue = "00:00"
        currentTimeLabel.font = NSFont.systemFont(ofSize: 12.0)
        currentTimeLabel.isEditable = false
        currentTimeLabel.isSelectable = false
        currentTimeLabel.drawsBackground = false
        currentTimeLabel.alignment = .right
        
        // 配置总时长标签
        durationLabel.stringValue = "00:00"
        durationLabel.font = NSFont.systemFont(ofSize: 12.0)
        currentTimeLabel.isEditable = false
        currentTimeLabel.isSelectable = false
        currentTimeLabel.drawsBackground = false
        durationLabel.alignment = .left
        
        // 配置进度条
        progressSlider.minValue = 0
        progressSlider.maxValue = 100
        progressSlider.doubleValue = 0
        progressSlider.isContinuous = true
        progressSlider.target = self
        progressSlider.action = #selector(progressSliderChanged(_:))
        
        // 配置播放/暂停按钮
        playPauseButton.bezelStyle = .circular
        playPauseButton.setButtonType(.momentaryChange)
        playPauseButton.image = NSImage(systemSymbolName: "play.fill", accessibilityDescription: "播放")
        playPauseButton.alternateImage = NSImage(systemSymbolName: "pause.fill", accessibilityDescription: "暂停")
        playPauseButton.target = self
        playPauseButton.action = #selector(playPauseButtonClicked(_:))
        playPauseButton.toolTip = "播放/暂停"
        
        // 配置停止按钮
        stopButton.bezelStyle = .circular
        stopButton.image = NSImage(systemSymbolName: "stop.fill", accessibilityDescription: "停止")
        stopButton.target = self
        stopButton.action = #selector(stopButtonClicked(_:))
        stopButton.toolTip = "停止"
        
        // 配置快进按钮
        forwardButton.bezelStyle = .circular
        forwardButton.image = NSImage(systemSymbolName: "goforward.15", accessibilityDescription: "快进")
        forwardButton.target = self
        forwardButton.action = #selector(forwardButtonClicked(_:))
        forwardButton.toolTip = "快进15秒"
        
        // 配置快退按钮
        backwardButton.bezelStyle = .circular
        backwardButton.image = NSImage(systemSymbolName: "gobackward.15", accessibilityDescription: "快退")
        backwardButton.target = self
        backwardButton.action = #selector(backwardButtonClicked(_:))
        backwardButton.toolTip = "快退15秒"
        
        // 配置音量按钮
        volumeButton.bezelStyle = .circular
        volumeButton.image = NSImage(systemSymbolName: "speaker.wave.2.fill", accessibilityDescription: "音量")
        volumeButton.alternateImage = NSImage(systemSymbolName: "speaker.slash.fill", accessibilityDescription: "静音")
        volumeButton.target = self
        volumeButton.action = #selector(volumeButtonClicked(_:))
        volumeButton.toolTip = "静音/取消静音"
        
        // 配置音量滑块
        volumeSlider.minValue = 0
        volumeSlider.maxValue = 100
        volumeSlider.doubleValue = 100
        volumeSlider.isContinuous = true
        volumeSlider.target = self
        volumeSlider.action = #selector(volumeSliderChanged(_:))
        
        // 将所有组件添加到ContentView
        let subviews = [mediaTitleLabel, currentTimeLabel, durationLabel, progressSlider, 
                        playPauseButton, stopButton, forwardButton, backwardButton, 
                        volumeButton, volumeSlider]
        subviews.forEach { contentView.addSubview($0) }
        
        // 设置布局约束
        setupConstraints()
    }
    
    // MARK: - Layout Constraints
    
    private func setupConstraints() {
        // 禁用所有视图的autoresizing mask
        let subviews = [mediaTitleLabel, currentTimeLabel, durationLabel, progressSlider, 
                        playPauseButton, stopButton, forwardButton, backwardButton, 
                        volumeButton, volumeSlider]
        subviews.forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // 媒体标题约束
        NSLayoutConstraint.activate([
            mediaTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10.0),
            mediaTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20.0),
            mediaTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20.0),
            mediaTitleLabel.heightAnchor.constraint(equalToConstant: 20.0)
        ])
        
        // 进度条约束
        NSLayoutConstraint.activate([
            progressSlider.topAnchor.constraint(equalTo: mediaTitleLabel.bottomAnchor, constant: 10.0),
            progressSlider.leadingAnchor.constraint(equalTo: currentTimeLabel.trailingAnchor, constant: 10.0),
            progressSlider.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -10.0),
            progressSlider.heightAnchor.constraint(equalToConstant: 20.0)
        ])
        
        // 当前时间标签约束
        NSLayoutConstraint.activate([
            currentTimeLabel.topAnchor.constraint(equalTo: mediaTitleLabel.bottomAnchor, constant: 10.0),
            currentTimeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20.0),
            currentTimeLabel.widthAnchor.constraint(equalToConstant: 50.0),
            currentTimeLabel.heightAnchor.constraint(equalToConstant: 20.0)
        ])
        
        // 总时长标签约束
        NSLayoutConstraint.activate([
            durationLabel.topAnchor.constraint(equalTo: mediaTitleLabel.bottomAnchor, constant: 10.0),
            durationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20.0),
            durationLabel.widthAnchor.constraint(equalToConstant: 50.0),
            durationLabel.heightAnchor.constraint(equalToConstant: 20.0)
        ])
        
        // 控制按钮容器
        let controlButtonsStackView = NSStackView(views: [backwardButton, playPauseButton, stopButton, forwardButton])
        controlButtonsStackView.orientation = .horizontal
        controlButtonsStackView.distribution = .fillEqually
        controlButtonsStackView.spacing = 10.0
        controlButtonsStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(controlButtonsStackView)
        
        // 音量控制容器
        let volumeControlStackView = NSStackView(views: [volumeButton, volumeSlider])
        volumeControlStackView.orientation = .horizontal
        volumeControlStackView.alignment = .centerY
        volumeControlStackView.spacing = 5.0
        volumeControlStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(volumeControlStackView)
        
        // 控制按钮容器约束
        NSLayoutConstraint.activate([
            controlButtonsStackView.topAnchor.constraint(equalTo: progressSlider.bottomAnchor, constant: 15.0),
            controlButtonsStackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            controlButtonsStackView.widthAnchor.constraint(equalToConstant: 200.0),
            controlButtonsStackView.heightAnchor.constraint(equalToConstant: 32.0)
        ])
        
        // 音量控制容器约束
        NSLayoutConstraint.activate([
            volumeControlStackView.topAnchor.constraint(equalTo: progressSlider.bottomAnchor, constant: 15.0),
            volumeControlStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20.0),
            volumeControlStackView.heightAnchor.constraint(equalToConstant: 32.0),
            volumeControlStackView.widthAnchor.constraint(equalToConstant: 100.0)
        ])
        
        // 底部约束
        NSLayoutConstraint.activate([
            controlButtonsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15.0)
        ])
    }
    
    // MARK: - Event Listeners
    
    private func setupEventListeners() {
        // 注册渲染器事件监听器
        let rendererManager = RendererManager.shared
        rendererManager.addRendererChangeListener(self)
    }
    
    // MARK: - Update Methods
    
    /// 更新当前渲染器
    func updateCurrentRenderer(_ renderer: DLNARendererProtocol?) {
        currentRenderer = renderer
        
        if let renderer = renderer {
            // 更新媒体信息
            updateMediaInfo(renderer.getMediaInfo())
            
            // 更新播放状态
            updatePlaybackState(renderer.playbackState)
            
            // 更新音量信息
            updateVolumeInfo(renderer.volumeInfo)
            
            // 开始播放位置更新计时器
            startPositionUpdateTimer()
        } else {
            // 清除媒体信息
            clearMediaInfo()
            
            // 停止播放位置更新计时器
            stopPositionUpdateTimer()
        }
    }
    
    /// 更新媒体信息
    private func updateMediaInfo(_ mediaInfo: DLNAMediaInfo?) {
        if let mediaInfo = mediaInfo {
            // 更新媒体标题
            mediaTitleLabel.stringValue = mediaInfo.title ?? "未知媒体"
            
            // 更新时长显示
            let duration = mediaInfo.duration
            durationLabel.stringValue = formatTime(duration)
            
            // 更新进度条最大值
            progressSlider.maxValue = duration
        } else {
            clearMediaInfo()
        }
    }
    
    /// 清除媒体信息
    private func clearMediaInfo() {
        mediaTitleLabel.stringValue = "无媒体播放"
        currentTimeLabel.stringValue = "00:00"
        durationLabel.stringValue = "00:00"
        progressSlider.maxValue = 100
        progressSlider.doubleValue = 0
    }
    
    /// 更新播放状态
    private func updatePlaybackState(_ state: DLNAPlaybackState) {
        switch state {
        case .playing:
            playPauseButton.state = .on
        case .paused, .stopped, .transitioning, .error, .unknown:
            playPauseButton.state = .off
        }
    }
    
    /// 更新音量信息
    private func updateVolumeInfo(_ volumeInfo: DLNAVolumeInfo) {
        volumeSlider.doubleValue = Double(volumeInfo.volume)
        volumeButton.state = volumeInfo.muted ? .on : .off
    }
    
    /// 更新播放位置
    private func updatePlaybackPosition() {
        guard let renderer = currentRenderer else { return }
        
        let currentPosition = renderer.getCurrentPosition()
        progressSlider.doubleValue = currentPosition
        currentTimeLabel.stringValue = formatTime(currentPosition)
    }
    
    /// 开始播放位置更新计时器
    private func startPositionUpdateTimer() {
        stopPositionUpdateTimer()
        
        positionUpdateTimer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(updatePlaybackPositionTimer),
            userInfo: nil,
            repeats: true
        )
    }
    
    /// 停止播放位置更新计时器
    private func stopPositionUpdateTimer() {
        positionUpdateTimer?.invalidate()
        positionUpdateTimer = nil
    }
    
    // MARK: - Helper Methods
    
    /// 格式化时间显示 (秒 -> mm:ss)
    private func formatTime(_ seconds: Double) -> String {
        let intSeconds = Int(seconds)
        let minutes = intSeconds / 60
        let remainingSeconds = intSeconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    // MARK: - Actions
    
    @objc private func playPauseButtonClicked(_ sender: NSButton) {
        guard let renderer = currentRenderer else { return }
        
        do {
            if renderer.playbackState == .playing {
                try renderer.pause()
            } else {
                try renderer.play()
            }
        } catch {
            print("播放控制错误: \(error)")
        }
    }
    
    @objc private func stopButtonClicked(_ sender: NSButton) {
        guard let renderer = currentRenderer else { return }
        
        do {
            try renderer.stop()
        } catch {
            print("停止播放错误: \(error)")
        }
    }
    
    @objc private func forwardButtonClicked(_ sender: NSButton) {
        guard let renderer = currentRenderer else { return }
        
        do {
            try renderer.seekForward(seconds: 15)
        } catch {
            print("快进错误: \(error)")
        }
    }
    
    @objc private func backwardButtonClicked(_ sender: NSButton) {
        guard let renderer = currentRenderer else { return }
        
        do {
            try renderer.seekBackward(seconds: 15)
        } catch {
            print("快退错误: \(error)")
        }
    }
    
    @objc private func progressSliderChanged(_ sender: NSSlider) {
        guard let renderer = currentRenderer else { return }
        
        let newPosition = sender.doubleValue
        
        do {
            try renderer.seekTo(position: newPosition)
        } catch {
            print("跳转到位置错误: \(error)")
        }
    }
    
    @objc private func volumeButtonClicked(_ sender: NSButton) {
        guard let renderer = currentRenderer else { return }
        
        do {
            try renderer.setMuted(muted: !renderer.volumeInfo.muted)
        } catch {
            print("设置静音错误: \(error)")
        }
    }
    
    @objc private func volumeSliderChanged(_ sender: NSSlider) {
        guard let renderer = currentRenderer else { return }
        
        let newVolume = Int(sender.doubleValue)
        
        do {
            try renderer.setVolume(volume: newVolume)
        } catch {
            print("设置音量错误: \(error)")
        }
    }
    
    @objc private func updatePlaybackPositionTimer() {
        updatePlaybackPosition()
    }
    
    // MARK: - Show Window
    
    func showWindow() {
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }
    
    // MARK: - Hide Window
    
    func hideWindow() {
        window?.orderOut(nil)
    }
}

// MARK: - RendererChangeListener

extension MediaControlWindowController: RendererChangeListener {
    func rendererChanged(_ renderer: DLNARendererProtocol?) {
        updateCurrentRenderer(renderer)
    }
    
    func rendererStateChanged(_ renderer: DLNARendererProtocol, state: DLNAPlaybackState) {
        updatePlaybackState(state)
    }
}