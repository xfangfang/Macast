import Cocoa
import Foundation

// MARK: - StatusMenuController

/// 状态栏菜单控制器
class StatusMenuController {
    
    // MARK: - Properties
    
    /// 应用程序主菜单
    let menu = NSMenu()
    
    /// 状态栏项
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    /// 服务是否正在运行
    var isServiceRunning = false
    
    /// 协议管理器
    private let protocolManager = ProtocolManager.shared
    
    /// 渲染器管理器
    private let rendererManager = RendererManager.shared

    var currentRenderer: DLNARendererProtocol? {
        rendererManager.currentRenderer
    }
    
    /// 默认渲染器 (MPV)
    private var defaultRenderer: DLNAMediaRenderer?
    
    // MARK: - Initialization
    
    /// 初始化方法
    init() {
        setupStatusMenu()
        setupNotificationObservers()
        
        // 默认启动服务
        startService()
    }
    
    // MARK: - Private Methods
    
    /// 设置状态栏菜单
    private func setupStatusMenu() {
        // 设置状态栏图标
        if let button = statusItem.button {
            if let iconPath = Bundle.main.path(forResource: "icon", ofType: "png", inDirectory: "assets"),
               let iconImage = NSImage(contentsOfFile: iconPath) {
                button.image = iconImage
            } else {
                button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Macast")
            }
            
            button.toolTip = "Macast"
        }
        
        // 添加状态显示项
        menu.addItem(NSMenuItem(title: "服务状态: 已停止", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // 添加服务控制项
        menu.addItem(NSMenuItem(title: "启动服务", action: #selector(startService), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "停止服务", action: #selector(stopService), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // 添加渲染器选择项
        menu.addItem(NSMenuItem(title: "选择渲染器", action: nil, keyEquivalent: ""))
        
        // 添加设置项
        menu.addItem(NSMenuItem(title: "偏好设置", action: #selector(openPreferences), keyEquivalent: ""))
        
        // 添加关于项
        menu.addItem(NSMenuItem(title: "关于", action: #selector(openAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // 添加退出项
        menu.addItem(NSMenuItem(title: "退出", action: #selector(exitApplication), keyEquivalent: "q"))
        
        // 设置菜单
        statusItem.menu = menu
    }
    
    /// 设置通知观察者
    private func setupNotificationObservers() {
        // 监听应用程序退出通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
        
        // 监听服务状态变更通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(serviceStatusChanged),
            name: Notification.Name("ServiceStatusChanged"),
            object: nil
        )
    }
    
    /// 更新状态显示
    private func updateStatusDisplay() {
        if let statusItem = menu.item(at: 0) { // 第一个菜单项是状态显示
            let statusText = isServiceRunning ? "正在运行" : "已停止"
            statusItem.title = "服务状态: " + statusText
        }
    }
    
    // MARK: - Action Methods
    
    /// 启动服务
    @objc func startService() {
        // 使用协议管理器启动所有协议
        protocolManager.startAllProtocols()
        
        // 启动默认渲染器
        if defaultRenderer == nil {
            defaultRenderer = DLNAMediaRenderer()
        }
        defaultRenderer?.start()
        
        // 更新服务状态
        isServiceRunning = true
        updateStatusDisplay()
        
        // 发送服务状态变更通知
        NotificationCenter.default.post(name: Notification.Name("ServiceStatusChanged"), object: nil, userInfo: ["isRunning": true])
        
        print("Macast服务已启动")
    }
    
    /// 停止服务
    @objc func stopService() {
        // 使用协议管理器停止所有协议
        protocolManager.stopAllProtocols()
        
        // 停止默认渲染器
        defaultRenderer?.stop()
        defaultRenderer = nil
        
        // 更新服务状态
        isServiceRunning = false
        updateStatusDisplay()
        
        // 发送服务状态变更通知
        NotificationCenter.default.post(name: Notification.Name("ServiceStatusChanged"), object: nil, userInfo: ["isRunning": false])
        
        print("Macast服务已停止")
    }
    
    /// 打开偏好设置
    @objc func openPreferences() {
        let preferencesWindowController = PreferencesWindowController()
        preferencesWindowController.showWindow(nil)
        
        print("打开偏好设置")
    }
    
    /// 打开关于窗口
    @objc func openAbout() {
        let aboutWindowController = AboutWindowController()
        aboutWindowController.showWindow(nil)
        
        print("打开关于窗口")
    }
    
    /// 退出应用程序
    @objc func exitApplication() {
        // 停止服务
        stopService()
        
        // 退出应用程序
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Notification Handlers
    
    /// 应用程序将退出时的处理
    @objc func applicationWillTerminate() {
        // 停止服务
        stopService()
        
        // 移除通知观察者
        NotificationCenter.default.removeObserver(self)
        
        print("Macast应用程序将退出")
    }
    
    /// 服务状态变更时的处理
    @objc func serviceStatusChanged(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let isRunning = userInfo["isRunning"] as? Bool {
            isServiceRunning = isRunning
            updateStatusDisplay()
        }
    }
}
