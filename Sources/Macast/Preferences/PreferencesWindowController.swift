import AppKit

// MARK: - PreferencesWindowController

/// 偏好设置窗口控制器
class PreferencesWindowController: NSWindowController {
    
    // MARK: - Properties
    
    /// 设置对象
    private let settings = Settings.shared
    
    /// 渲染器选项
    private let rendererOptions = ["MPV", "IINA", "VLC"]
    
    // MARK: - UI Elements
    
    /// 内容视图
    private let contentView = NSView()
    
    /// 关闭按钮
    private let closeButton = NSButton()
    
    /// 应用按钮
    private let applyButton = NSButton()
    
    /// 重置按钮
    private let resetButton = NSButton()
    
    /// 默认渲染器选择器
    private let rendererPopup = NSPopUpButton()
    
    /// 外观模式选择器
    private let appearancePopup = NSPopUpButton()
    
    /// 通知启用复选框
    private let notificationsEnabledCheckbox = NSButton()
    
    /// 服务状态通知复选框
    private let serviceStatusNotificationsCheckbox = NSButton()
    
    /// 媒体播放通知复选框
    private let mediaPlaybackNotificationsCheckbox = NSButton()
    
    // MARK: - Initialization
    
    init() {
        // 创建窗口
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 350),
                              styleMask: [.titled, .closable, .resizable, .miniaturizable],
                              backing: .buffered,
                              defer: false)
        
        // 设置窗口属性
        window.title = "偏好设置"
        window.center()
        window.isReleasedWhenClosed = false
        window.styleMask.insert(.unifiedTitleAndToolbar)
        window.titlebarAppearsTransparent = true
        window.toolbar = NSToolbar()
        window.toolbar?.displayMode = .iconOnly
        window.setFrame(NSRect(x: 0, y: 0, width: 400, height: 200), display: true)
        
        // 初始化窗口控制器
        super.init(window: window)
        
        // 设置内容视图
        window.contentView = contentView
        
        // 配置UI元素
        configureUIElements()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    
    override func windowDidLoad() {
        super.windowDidLoad()
    }
    
    // MARK: - UI Configuration
    
    /// 配置UI元素
    private func configureUIElements() {
        // 设置布局约束
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建标题标签
        let rendererLabel = NSTextField(labelWithString: "默认渲染器:")
        rendererLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置渲染器弹出按钮
        rendererPopup.translatesAutoresizingMaskIntoConstraints = false
        rendererPopup.removeAllItems()
        for renderer in rendererOptions {
            rendererPopup.addItem(withTitle: renderer)
        }
        rendererPopup.toolTip = "选择默认媒体渲染器"
        
        // 配置外观模式弹出按钮
        appearancePopup.translatesAutoresizingMaskIntoConstraints = false
        appearancePopup.removeAllItems()
        appearancePopup.addItem(withTitle: "跟随系统")
        appearancePopup.addItem(withTitle: "浅色模式")
        appearancePopup.addItem(withTitle: "暗色模式")
        appearancePopup.toolTip = "选择应用程序外观模式"
        
        // 配置通知启用复选框
        notificationsEnabledCheckbox.translatesAutoresizingMaskIntoConstraints = false
        notificationsEnabledCheckbox.setButtonType(.switch)
        notificationsEnabledCheckbox.title = "启用通知"
        notificationsEnabledCheckbox.state = .on
        notificationsEnabledCheckbox.target = self
        notificationsEnabledCheckbox.action = #selector(notificationsEnabledChanged(_:))
        notificationsEnabledCheckbox.toolTip = "启用或禁用所有Macast通知"
        
        // 配置服务状态通知复选框
        serviceStatusNotificationsCheckbox.translatesAutoresizingMaskIntoConstraints = false
        serviceStatusNotificationsCheckbox.setButtonType(.switch)
        serviceStatusNotificationsCheckbox.title = "服务状态通知"
        serviceStatusNotificationsCheckbox.state = .on
        serviceStatusNotificationsCheckbox.target = self
        serviceStatusNotificationsCheckbox.action = #selector(serviceStatusNotificationsChanged(_:))
        serviceStatusNotificationsCheckbox.toolTip = "接收服务启动/停止通知"
        
        // 配置媒体播放通知复选框
        mediaPlaybackNotificationsCheckbox.translatesAutoresizingMaskIntoConstraints = false
        mediaPlaybackNotificationsCheckbox.setButtonType(.switch)
        mediaPlaybackNotificationsCheckbox.title = "媒体播放通知"
        mediaPlaybackNotificationsCheckbox.state = .on
        mediaPlaybackNotificationsCheckbox.target = self
        mediaPlaybackNotificationsCheckbox.action = #selector(mediaPlaybackNotificationsChanged(_:))
        mediaPlaybackNotificationsCheckbox.toolTip = "接收媒体播放状态通知"
        
        // 配置按钮
        let buttonWidth: CGFloat = 80
        let buttonHeight: CGFloat = 32
        
        closeButton.title = "关闭"
        closeButton.bezelStyle = .rounded
        closeButton.target = self
        closeButton.action = #selector(closeButtonClicked)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.toolTip = "关闭偏好设置窗口"
        closeButton.keyEquivalent = "w" // Command+W
        
        applyButton.title = "应用"
        applyButton.bezelStyle = .rounded
        applyButton.target = self
        applyButton.action = #selector(applyButtonClicked)
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        applyButton.toolTip = "保存当前设置"
        applyButton.keyEquivalent = "\r" // Enter键
        
        resetButton.title = "重置默认"
        resetButton.bezelStyle = .rounded
        resetButton.target = self
        resetButton.action = #selector(resetToDefaultsButtonClicked)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.toolTip = "将所有设置恢复为默认值"
        resetButton.keyEquivalent = "\u{1f}" // Escape键
        
        // 创建外观模式标签
        let appearanceLabel = NSTextField(labelWithString: "外观模式:")
        appearanceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建通知设置标题
        let notificationsLabel = NSTextField(labelWithString: "通知设置:")
        notificationsLabel.translatesAutoresizingMaskIntoConstraints = false
        notificationsLabel.font = NSFont.boldSystemFont(ofSize: 13)
        
        // 创建通知设置分隔线
        let notificationsSeparator = NSBox()
        notificationsSeparator.translatesAutoresizingMaskIntoConstraints = false
        notificationsSeparator.boxType = .separator
        
        // 添加子视图
        contentView.addSubview(rendererLabel)
        contentView.addSubview(rendererPopup)
        contentView.addSubview(appearanceLabel)
        contentView.addSubview(appearancePopup)
        contentView.addSubview(notificationsLabel)
        contentView.addSubview(notificationsSeparator)
        contentView.addSubview(notificationsEnabledCheckbox)
        contentView.addSubview(serviceStatusNotificationsCheckbox)
        contentView.addSubview(mediaPlaybackNotificationsCheckbox)
        contentView.addSubview(closeButton)
        contentView.addSubview(applyButton)
        contentView.addSubview(resetButton)
        
        // 添加约束
        NSLayoutConstraint.activate([
            // 渲染器设置
            rendererLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            rendererLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            rendererPopup.topAnchor.constraint(equalTo: rendererLabel.bottomAnchor, constant: 10),
            rendererPopup.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            rendererPopup.widthAnchor.constraint(equalToConstant: 150),
            
            // 外观模式设置
            appearanceLabel.topAnchor.constraint(equalTo: rendererPopup.bottomAnchor, constant: 20),
            appearanceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            appearancePopup.topAnchor.constraint(equalTo: appearanceLabel.bottomAnchor, constant: 10),
            appearancePopup.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            appearancePopup.widthAnchor.constraint(equalToConstant: 150),
            
            // 通知设置
            notificationsLabel.topAnchor.constraint(equalTo: appearancePopup.bottomAnchor, constant: 25),
            notificationsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            notificationsSeparator.topAnchor.constraint(equalTo: notificationsLabel.bottomAnchor, constant: 5),
            notificationsSeparator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            notificationsSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            notificationsSeparator.heightAnchor.constraint(equalToConstant: 2),
            
            notificationsEnabledCheckbox.topAnchor.constraint(equalTo: notificationsSeparator.bottomAnchor, constant: 10),
            notificationsEnabledCheckbox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            notificationsEnabledCheckbox.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            serviceStatusNotificationsCheckbox.topAnchor.constraint(equalTo: notificationsEnabledCheckbox.bottomAnchor, constant: 10),
            serviceStatusNotificationsCheckbox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            serviceStatusNotificationsCheckbox.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            mediaPlaybackNotificationsCheckbox.topAnchor.constraint(equalTo: serviceStatusNotificationsCheckbox.bottomAnchor, constant: 10),
            mediaPlaybackNotificationsCheckbox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            mediaPlaybackNotificationsCheckbox.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // 按钮布局
            closeButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            closeButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            
            applyButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            applyButton.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -10),
            applyButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            applyButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            
            resetButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            resetButton.trailingAnchor.constraint(equalTo: applyButton.leadingAnchor, constant: -10),
            resetButton.widthAnchor.constraint(equalToConstant: buttonWidth + 20),
            resetButton.heightAnchor.constraint(equalToConstant: buttonHeight),
        ])
        
        // 加载设置到UI
        loadSettingsToUI()
    }
    
    // MARK: - Settings Management
    
    /// 加载设置到UI
    private func loadSettingsToUI() {
        // 选择当前默认渲染器
        for item in rendererPopup.itemArray {
            if item.title == settings.defaultRenderer {
                rendererPopup.select(item)
                break
            }
        }
        
        // 选择当前外观模式
        switch settings.appearanceMode {
        case "light":
            appearancePopup.selectItem(at: 1)
        case "dark":
            appearancePopup.selectItem(at: 2)
        default:
            appearancePopup.selectItem(at: 0)
        }
        
        // 加载通知设置
        let notificationManager = NotificationManager.shared
        notificationsEnabledCheckbox.state = notificationManager.notificationsEnabled ? .on : .off
        serviceStatusNotificationsCheckbox.state = notificationManager.serviceStatusNotificationsEnabled ? .on : .off
        mediaPlaybackNotificationsCheckbox.state = notificationManager.mediaPlaybackNotificationsEnabled ? .on : .off
        
        // 更新通知复选框的启用状态
        updateNotificationCheckboxStates()
    }
    
    /// 保存UI设置到设置对象
    private func saveSettingsFromUI() {
        // 保存渲染器设置
        settings.defaultRenderer = rendererPopup.selectedItem?.title ?? "MPV"
        
        // 保存外观模式设置
        let selectedIndex = appearancePopup.indexOfSelectedItem
        switch selectedIndex {
        case 1:
            settings.appearanceMode = "light"
        case 2:
            settings.appearanceMode = "dark"
        default:
            settings.appearanceMode = "system"
        }
        
        // 更新应用程序外观
        updateApplicationAppearance()
        
        // 保存通知设置
        let notificationManager = NotificationManager.shared
        notificationManager.notificationsEnabled = notificationsEnabledCheckbox.state == .on
        notificationManager.serviceStatusNotificationsEnabled = serviceStatusNotificationsCheckbox.state == .on
        notificationManager.mediaPlaybackNotificationsEnabled = mediaPlaybackNotificationsCheckbox.state == .on
        notificationManager.saveSettings()
        
        // 保存设置
        settings.saveSettings()
        
        // 显示成功提示
        let alert = NSAlert()
        alert.messageText = "设置已保存"
        alert.informativeText = "您的设置已成功应用"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
    
    // MARK: - Actions
    
    /// 更新应用程序外观
    private func updateApplicationAppearance() {
        switch settings.appearanceMode {
        case "light":
            NSApp.appearance = NSAppearance(named: .aqua)
        case "dark":
            NSApp.appearance = NSAppearance(named: .darkAqua)
        default:
            NSApp.appearance = nil // 跟随系统设置
        }
    }
    
    /// 重置所有设置为默认值
    @objc private func resetToDefaultsButtonClicked() {
        // 显示确认对话框
        let alert = NSAlert()
        alert.messageText = "重置默认设置"
        alert.informativeText = "确定要将所有设置重置为默认值吗？"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")
        
        // 处理用户响应
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // 重置设置
            settings.resetToDefaults()
            
            // 重新加载设置到UI
            loadSettingsToUI()
            
            // 更新应用程序外观
            updateApplicationAppearance()
        }
    }
    
    /// 更新通知复选框状态
    private func updateNotificationCheckboxStates() {
        let enabled = notificationsEnabledCheckbox.state == .on
        serviceStatusNotificationsCheckbox.isEnabled = enabled
        mediaPlaybackNotificationsCheckbox.isEnabled = enabled
    }
    
    /// 通知启用状态变化处理
    @objc private func notificationsEnabledChanged(_ sender: NSButton) {
        updateNotificationCheckboxStates()
    }
    
    /// 服务状态通知变化处理
    @objc private func serviceStatusNotificationsChanged(_ sender: NSButton) {
        // 无需额外处理，状态会在保存时更新
    }
    
    /// 媒体播放通知变化处理
    @objc private func mediaPlaybackNotificationsChanged(_ sender: NSButton) {
        // 无需额外处理，状态会在保存时更新
    }
    
    /// 应用设置
    @objc private func applyButtonClicked() {
        saveSettingsFromUI()
    }
    
    /// 关闭窗口
    @objc private func closeButtonClicked() {
        window?.close()
    }
}
