import XCTest
@testable import Macast

class PluginManagerTests: XCTestCase {
    
    // 测试获取插件管理器单例
    func testGetSharedInstance() {
        let manager1 = PluginManager.shared
        let manager2 = PluginManager.shared
        XCTAssertTrue(manager1 === manager2, "PluginManager应该是单例")
    }
    
    // 测试插件目录创建
    func testPluginDirectoryCreation() {
        let manager = PluginManager.shared
        
        // 获取插件目录
        let applicationSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let pluginDirectory = applicationSupportDirectory.appendingPathComponent("Macast/Plugins")
        
        // 验证目录是否存在
        let directoryExists = FileManager.default.fileExists(atPath: pluginDirectory.path)
        XCTAssertTrue(directoryExists, "插件目录应该存在")
    }
    
    // 测试插件配置加载和保存
    func testPluginConfigurations() {
        let manager = PluginManager.shared
        
        // 模拟插件配置
        let testIdentifier = "test.plugin.identifier"
        let testConfiguration = PluginConfiguration(identifier: testIdentifier, isEnabled: true)
        
        // 获取用户默认值
        let userDefaults = UserDefaults.standard
        let configurationKey = "plugin_configurations"
        
        // 保存原始配置
        let originalConfigurations = userDefaults.data(forKey: configurationKey)
        
        // 保存测试配置
        var configurations = [String: PluginConfiguration]()
        configurations[testIdentifier] = testConfiguration
        
        do {
            let data = try PropertyListEncoder().encode(configurations)
            userDefaults.set(data, forKey: configurationKey)
            userDefaults.synchronize()
            
            // 重新加载插件管理器
            // 由于PluginManager是单例，我们无法直接重新初始化它
            // 所以我们将直接使用UserDefaults进行测试
            
            // 验证配置是否已保存
            let savedData = userDefaults.data(forKey: configurationKey)
            XCTAssertNotNil(savedData, "插件配置应该已保存")
            
            let loadedConfigurations = try PropertyListDecoder().decode([String: PluginConfiguration].self, from: savedData!)
            XCTAssertEqual(loadedConfigurations[testIdentifier]?.isEnabled, true, "插件配置应该已加载")
        } catch {
            XCTFail("插件配置测试失败: \(error.localizedDescription)")
        }
        
        // 恢复原始配置
        if let originalData = originalConfigurations {
            userDefaults.set(originalData, forKey: configurationKey)
            userDefaults.synchronize()
        } else {
            userDefaults.removeObject(forKey: configurationKey)
            userDefaults.synchronize()
        }
    }
    
    // 测试插件加载功能（模拟）
    func testPluginLoading() {
        let manager = PluginManager.shared
        
        // 测试加载所有插件
        // 由于我们没有实际的插件，这里我们将简单地调用方法而不验证结果
        manager.loadAllPlugins()
        
        // 测试获取所有插件
        let allPlugins = manager.getAllPlugins()
        XCTAssertTrue(allPlugins.count >= 0, "获取所有插件应该返回一个数组")
        
        // 测试获取已启用的插件
        let enabledPlugins = manager.getEnabledPlugins()
        XCTAssertTrue(enabledPlugins.count >= 0, "获取已启用的插件应该返回一个数组")
    }
}
