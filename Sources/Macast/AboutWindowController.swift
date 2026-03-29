import AppKit

class AboutWindowController: NSWindowController {
    static let shared = AboutWindowController()
    
    // MARK: - UI Components
    
    private let contentView = NSView()
    private let appIcon = NSImageView()
    private let appNameLabel = NSTextField()
    private let appVersionLabel = NSTextField()
    private let appDescriptionLabel = NSTextField()
    private let copyrightLabel = NSTextField()
    private let websiteButton = NSButton()
    private let closeButton = NSButton()
    
    // MARK: - Initialization
    
    override init(window: NSWindow?) {
        super.init(window: window)
        setupWindow()
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWindow()
        setupUI()
    }
    
    // MARK: - Window Setup
    
    private func setupWindow() {
        // 创建窗口
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .borderless],
            backing: .buffered,
            defer: false
        )
        
        // 设置窗口属性
        window.title = "关于 Macast"
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
        contentView.layer?.backgroundColor = NSColor.white.cgColor
        
        // 配置应用图标
        // 使用自定义图标
        if let iconPath = Bundle.main.path(forResource: "icon", ofType: "png", inDirectory: "assets"),
           let iconImage = NSImage(contentsOfFile: iconPath) {
            appIcon.image = iconImage
        } else {
            // 回退到系统默认图标
            appIcon.image = NSImage(systemSymbolName: "music.note.house.fill", accessibilityDescription: "Macast 应用图标")
        }
        appIcon.imageScaling = .scaleProportionallyUpOrDown
        appIcon.wantsLayer = true
        appIcon.layer?.cornerRadius = 12.0
        appIcon.layer?.masksToBounds = true
        
        // 配置应用名称标签
        appNameLabel.stringValue = "Macast"
        appNameLabel.font = NSFont.boldSystemFont(ofSize: 24.0)
        appNameLabel.isEditable = false
        appNameLabel.isSelectable = false
        appNameLabel.drawsBackground = false
        appNameLabel.alignment = .center
        
        // 配置应用版本标签
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        appVersionLabel.stringValue = "版本 \(version) (\(build))"
        appVersionLabel.font = NSFont.systemFont(ofSize: 14.0)
        appVersionLabel.isEditable = false
        appVersionLabel.isSelectable = false
        appVersionLabel.drawsBackground = false
        appVersionLabel.alignment = .center
        
        // 配置应用描述标签
        appDescriptionLabel.stringValue = "Macast 是一款基于Swift语言开发的macOS平台DLNA媒体渲染器应用程序，允许用户从移动设备将视频、图片或音乐推送到计算机进行播放。"
        appDescriptionLabel.font = NSFont.systemFont(ofSize: 13.0)
        appDescriptionLabel.isEditable = false
        appDescriptionLabel.isSelectable = false
        appDescriptionLabel.drawsBackground = false
        appDescriptionLabel.alignment = .center
        appDescriptionLabel.cell?.wraps = true
        appDescriptionLabel.cell?.isScrollable = false
        
        // 配置版权标签
        copyrightLabel.stringValue = "© 2026 Macast Team. All rights reserved."
        copyrightLabel.font = NSFont.systemFont(ofSize: 12.0)
        copyrightLabel.isEditable = false
        copyrightLabel.isSelectable = false
        copyrightLabel.drawsBackground = false
        copyrightLabel.alignment = .center
        
        // 配置网站按钮
        websiteButton.title = "访问官方网站"
        websiteButton.target = self
        websiteButton.action = #selector(openWebsite)
        websiteButton.bezelStyle = .rounded
        
        // 配置关闭按钮
        closeButton.title = "关闭"
        closeButton.target = self
        closeButton.action = #selector(closeWindow)
        closeButton.bezelStyle = .rounded
        closeButton.keyEquivalent = "\r" // Enter键
        
        // 将所有组件添加到ContentView
        let subviews = [appIcon, appNameLabel, appVersionLabel, appDescriptionLabel, copyrightLabel, websiteButton, closeButton]
        subviews.forEach { contentView.addSubview($0) }
        
        // 设置布局约束
        setupConstraints()
    }
    
    // MARK: - Layout Constraints
    
    private func setupConstraints() {
        // 禁用所有视图的autoresizing mask
        let subviews = [appIcon, appNameLabel, appVersionLabel, appDescriptionLabel, copyrightLabel, websiteButton, closeButton]
        subviews.forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // 应用图标约束
        NSLayoutConstraint.activate([
            appIcon.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            appIcon.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20.0),
            appIcon.widthAnchor.constraint(equalToConstant: 80.0),
            appIcon.heightAnchor.constraint(equalToConstant: 80.0)
        ])
        
        // 应用名称约束
        NSLayoutConstraint.activate([
            appNameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            appNameLabel.topAnchor.constraint(equalTo: appIcon.bottomAnchor, constant: 15.0),
            appNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20.0),
            appNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20.0)
        ])
        
        // 应用版本约束
        NSLayoutConstraint.activate([
            appVersionLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            appVersionLabel.topAnchor.constraint(equalTo: appNameLabel.bottomAnchor, constant: 5.0),
            appVersionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20.0),
            appVersionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20.0)
        ])
        
        // 应用描述约束
        NSLayoutConstraint.activate([
            appDescriptionLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            appDescriptionLabel.topAnchor.constraint(equalTo: appVersionLabel.bottomAnchor, constant: 15.0),
            appDescriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30.0),
            appDescriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30.0),
            appDescriptionLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 60.0)
        ])
        
        // 版权信息约束
        NSLayoutConstraint.activate([
            copyrightLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            copyrightLabel.topAnchor.constraint(equalTo: appDescriptionLabel.bottomAnchor, constant: 15.0),
            copyrightLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20.0),
            copyrightLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20.0)
        ])
        
        // 网站按钮约束
        NSLayoutConstraint.activate([
            websiteButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            websiteButton.topAnchor.constraint(equalTo: copyrightLabel.bottomAnchor, constant: 15.0),
            websiteButton.widthAnchor.constraint(equalToConstant: 120.0),
            websiteButton.heightAnchor.constraint(equalToConstant: 32.0)
        ])
        
        // 关闭按钮约束
        NSLayoutConstraint.activate([
            closeButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            closeButton.topAnchor.constraint(equalTo: websiteButton.bottomAnchor, constant: 10.0),
            closeButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20.0),
            closeButton.widthAnchor.constraint(equalToConstant: 80.0),
            closeButton.heightAnchor.constraint(equalToConstant: 32.0)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func openWebsite() {
        if let url = URL(string: "https://github.com/xfangfang/Macast") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func closeWindow() {
        window?.close()
    }
    
    // MARK: - Show Window
    
    func showWindow() {
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }
}
