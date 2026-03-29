import AppKit
import Foundation

// Macast macOS平台Swift重写应用程序入口

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusMenuController: StatusMenuController?
    var dlnarenderer: DLNAMediaRenderer?
    var httpServer: HTTPServer?
    var ssdpServer: SSDPServer?

    func applicationDidFinishLaunching(_: Notification) {
        // 创建状态栏菜单控制器 (这会自动启动所有服务和渲染器)
        statusMenuController = StatusMenuController()

        // 显示启动信息
        print("Macast Swift重写版本启动成功")
        print("状态栏菜单已创建，服务已启动")
    }
    
    func applicationWillTerminate(_: Notification) {
        // 状态栏控制器在销毁前会停止服务，但我们可以显式调用以确保安全
        statusMenuController?.stopService()
        print("Macast应用程序即将退出，服务已停止")
    }
}
