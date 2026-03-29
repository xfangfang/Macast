import AppKit
import Foundation

// Macast macOS平台Swift重写应用程序入口

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var menu: NSMenu?

    func applicationDidFinishLaunching(_: Notification) {
        // 创建状态栏项目
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        // 设置图标
        if let button = statusItem?.button {
            button.image = NSImage(named: "menu_light")
            button.image?.isTemplate = true
        }

        // 创建菜单
        createMenu()

        // 显示启动信息
        print("Macast Swift重写版本启动成功")
    }

    func createMenu() {
        menu = NSMenu()

        // 创建菜单项
        let startItem = NSMenuItem(title: "启动服务", action: #selector(startService), keyEquivalent: "")
        let stopItem = NSMenuItem(title: "停止服务", action: #selector(stopService), keyEquivalent: "")
        let preferencesItem = NSMenuItem(title: "偏好设置", action: #selector(openPreferences), keyEquivalent: ",")
        let aboutItem = NSMenuItem(title: "关于Macast", action: #selector(openAbout), keyEquivalent: "")
        let quitItem = NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q")

        // 添加分隔线
        menu?.addItem(startItem)
        menu?.addItem(stopItem)
        menu?.addItem(.separator())
        menu?.addItem(preferencesItem)
        menu?.addItem(aboutItem)
        menu?.addItem(.separator())
        menu?.addItem(quitItem)

        // 设置菜单
        statusItem?.menu = menu
    }

    @objc func startService() {
        print("启动服务")
    }

    @objc func stopService() {
        print("停止服务")
    }

    @objc func openPreferences() {
        print("打开偏好设置")
    }

    @objc func openAbout() {
        print("打开关于窗口")
    }

    @objc func quit() {
        print("退出应用")
        NSApplication.shared.terminate(self)
    }
}
