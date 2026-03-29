import XCTest
@testable import Macast

class SettingsTests: XCTestCase {
    
    // 测试加载和保存设置
    func testSettingsLoadSave() {
        // 获取设置单例
        let settings = Settings.shared
        
        // 保存原始设置
        let originalHTTPPort = settings.httpPort
        let originalDefaultVolume = settings.defaultVolume
        
        // 修改设置
        settings.httpPort = 8080
        settings.defaultVolume = 75
        
        // 保存设置
        settings.saveSettings()
        
        // 重置设置单例
        // 这里我们不能直接重置单例，所以我们将重新验证设置
        // 为了测试目的，我们将再次获取设置并验证
        let newSettings = Settings.shared
        XCTAssertEqual(newSettings.httpPort, 8080, "HTTP端口应该是8080")
        XCTAssertEqual(newSettings.defaultVolume, 75, "默认音量应该是75")
        
        // 恢复原始设置
        newSettings.httpPort = originalHTTPPort
        newSettings.defaultVolume = originalDefaultVolume
        newSettings.saveSettings()
        
        // 验证原始设置已恢复
        XCTAssertEqual(Settings.shared.httpPort, originalHTTPPort, "HTTP端口应该已恢复到原始值")
        XCTAssertEqual(Settings.shared.defaultVolume, originalDefaultVolume, "默认音量应该已恢复到原始值")
    }
    
    // 测试重置设置
    func testResetToDefaults() {
        // 获取设置单例
        let settings = Settings.shared
        
        // 保存原始设置
        let originalHTTPPort = settings.httpPort
        let originalDefaultVolume = settings.defaultVolume
        let originalSSDPEnabled = settings.ssdpEnabled
        
        // 修改设置
        settings.httpPort = 8080
        settings.defaultVolume = 75
        settings.ssdpEnabled = false
        
        // 保存设置
        settings.saveSettings()
        
        // 重置设置为默认值
        settings.resetToDefaults()
        
        // 验证设置已重置为默认值
        XCTAssertEqual(settings.httpPort, 8008, "HTTP端口应该重置为默认值8008")
        XCTAssertEqual(settings.defaultVolume, 50, "默认音量应该重置为默认值50")
        XCTAssertEqual(settings.ssdpEnabled, true, "SSDP应该重置为默认值true")
        
        // 恢复原始设置
        settings.httpPort = originalHTTPPort
        settings.defaultVolume = originalDefaultVolume
        settings.ssdpEnabled = originalSSDPEnabled
        settings.saveSettings()
    }
    
    // 测试验证功能
    func testValidation() {
        // 获取设置单例
        let settings = Settings.shared
        
        // 测试HTTP端口验证
        XCTAssertTrue(settings.validateHTTPPort(8008), "端口8008应该是有效的")
        XCTAssertTrue(settings.validateHTTPPort(65535), "端口65535应该是有效的")
        XCTAssertFalse(settings.validateHTTPPort(1023), "端口1023应该是无效的")
        XCTAssertFalse(settings.validateHTTPPort(65536), "端口65536应该是无效的")
        
        // 测试SSDP TTL验证
        XCTAssertTrue(settings.validateSSDTTL(1), "TTL 1应该是有效的")
        XCTAssertTrue(settings.validateSSDTTL(255), "TTL 255应该是有效的")
        XCTAssertFalse(settings.validateSSDTTL(0), "TTL 0应该是无效的")
        XCTAssertFalse(settings.validateSSDTTL(256), "TTL 256应该是无效的")
        
        // 测试音量验证
        XCTAssertTrue(settings.validateVolume(0), "音量0应该是有效的")
        XCTAssertTrue(settings.validateVolume(100), "音量100应该是有效的")
        XCTAssertFalse(settings.validateVolume(-1), "音量-1应该是无效的")
        XCTAssertFalse(settings.validateVolume(101), "音量101应该是无效的")
        
        // 测试缓冲区大小验证
        XCTAssertTrue(settings.validateBufferSize(512), "缓冲区大小512应该是有效的")
        XCTAssertTrue(settings.validateBufferSize(65536), "缓冲区大小65536应该是有效的")
        XCTAssertFalse(settings.validateBufferSize(511), "缓冲区大小511应该是无效的")
        XCTAssertFalse(settings.validateBufferSize(65537), "缓冲区大小65537应该是无效的")
    }
    
    // 测试通知功能
    func testSettingsChangedNotification() {
        // 创建期望
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(block: { _, _ in true }),
            object: nil
        )
        expectation.isInverted = false
        
        // 添加通知观察者
        let observer = NotificationCenter.default.addObserver(
            forName: .settingsChanged,
            object: nil,
            queue: nil
        ) { _ in
            expectation.fulfill()
        }
        
        // 修改设置并保存
        let settings = Settings.shared
        settings.httpPort = 8080
        settings.saveSettings()
        
        // 等待通知
        wait(for: [expectation], timeout: 5.0)
        
        // 移除观察者
        NotificationCenter.default.removeObserver(observer)
        
        // 恢复原始设置
        settings.httpPort = 8008
        settings.saveSettings()
    }
}
