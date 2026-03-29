import XCTest
@testable import Macast

// MARK: - Test Plugins for Dependency Tests

class TestPlugin1: MacastPlugin {
    var name: String = "Test Plugin 1"
    var version: String = "1.0.0"
    var identifier: String = "test.plugin.1"
    var description: String = "Test Plugin 1"
    var author: String = "Test"
    var isEnabled: Bool = true
    var isLoaded: Bool = true
    
    var dependencies: [PluginDependency] = [
        PluginDependency(pluginIdentifier: "test.plugin.2", minimumVersion: "1.0.0", isOptional: false)
    ]
    
    required init() {}
    
    func onLoad() {}
    func onUnload() {}
}

class TestPlugin2: MacastPlugin {
    var name: String = "Test Plugin 2"
    var version: String = "1.0.0"
    var identifier: String = "test.plugin.2"
    var description: String = "Test Plugin 2"
    var author: String = "Test"
    var isEnabled: Bool = true
    var isLoaded: Bool = true
    
    required init() {}
    
    func onLoad() {}
    func onUnload() {}
}

class TestPlugin3: MacastPlugin {
    var name: String = "Test Plugin 3"
    var version: String = "1.0.0"
    var identifier: String = "test.plugin.3"
    var description: String = "Test Plugin 3"
    var author: String = "Test"
    var isEnabled: Bool = true
    var isLoaded: Bool = true
    
    var dependencies: [PluginDependency] = [
        PluginDependency(pluginIdentifier: "test.plugin.2", minimumVersion: "2.0.0", isOptional: false),
        PluginDependency(pluginIdentifier: "test.plugin.4", minimumVersion: "1.0.0", isOptional: true)
    ]
    
    required init() {}
    
    func onLoad() {}
    func onUnload() {}
}

// MARK: - PluginDependencyTests

class PluginDependencyTests: XCTestCase {
    
    var pluginManager: PluginManager!
    
    override func setUp() {
        super.setUp()
        pluginManager = PluginManager.shared
        
        // 保存原始插件配置
        let userDefaults = UserDefaults.standard
        _ = userDefaults.data(forKey: "plugin_configurations")
        
        // 清除所有插件配置
        userDefaults.removeObject(forKey: "plugin_configurations")
        userDefaults.synchronize()
    }
    
    override func tearDown() {
        // 恢复原始插件配置
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: "plugin_configurations")
        userDefaults.synchronize()
        
        pluginManager = nil
        super.tearDown()
    }
    
    // 测试插件依赖验证 - 成功场景
    func testPluginDependencyValidation_Success() {
        // 创建测试插件
        let plugin2 = TestPlugin2()
        let plugin1 = TestPlugin1()
        
        // 模拟PluginManager的plugins字典
        pluginManager.plugins[plugin2.identifier] = plugin2
        pluginManager.plugins[plugin1.identifier] = plugin1
        
        do {
            try pluginManager.validatePluginDependencies(plugin1)
            XCTAssertTrue(true, "依赖验证应该成功")
        } catch {
            XCTFail("依赖验证失败: \(error.localizedDescription)")
        }
    }
    
    // 测试插件依赖验证 - 缺失依赖
    func testPluginDependencyValidation_MissingDependency() {
        // 创建测试插件
        let plugin1 = TestPlugin1()
        
        // 模拟PluginManager的plugins字典
        pluginManager.plugins[plugin1.identifier] = plugin1
        
        do {
            try pluginManager.validatePluginDependencies(plugin1)
            XCTFail("依赖验证应该失败，因为缺少依赖")
        } catch PluginError.missingDependency(let pluginName, let dependencyIdentifier) {
            XCTAssertEqual(pluginName, "Test Plugin 1", "插件名称应该匹配")
            XCTAssertEqual(dependencyIdentifier, "test.plugin.2", "依赖标识符应该匹配")
        } catch {
            XCTFail("依赖验证失败，但不是预期的错误类型: \(error.localizedDescription)")
        }
    }
    
    // 测试插件依赖验证 - 版本不匹配
    func testPluginDependencyValidation_VersionMismatch() {
        // 创建测试插件
        let plugin2 = TestPlugin2() // 版本1.0.0
        let plugin3 = TestPlugin3() // 需要plugin2版本2.0.0
        
        // 模拟PluginManager的plugins字典
        pluginManager.plugins[plugin2.identifier] = plugin2
        pluginManager.plugins[plugin3.identifier] = plugin3
        
        do {
            try pluginManager.validatePluginDependencies(plugin3)
            XCTFail("依赖验证应该失败，因为版本不匹配")
        } catch PluginError.dependencyVersionMismatch(let pluginName, let dependencyName, let requiredVersion, let actualVersion) {
            XCTAssertEqual(pluginName, "Test Plugin 3", "插件名称应该匹配")
            XCTAssertEqual(dependencyName, "Test Plugin 2", "依赖名称应该匹配")
            XCTAssertEqual(requiredVersion, "2.0.0", "所需版本应该匹配")
            XCTAssertEqual(actualVersion, "1.0.0", "实际版本应该匹配")
        } catch {
            XCTFail("依赖验证失败，但不是预期的错误类型: \(error.localizedDescription)")
        }
    }
    
    // 测试插件依赖验证 - 可选依赖缺失
    func testPluginDependencyValidation_OptionalDependencyMissing() {
        // 创建测试插件
        let plugin2 = TestPlugin2()
        plugin2.version = "2.0.0"
        let plugin3 = TestPlugin3()
        
        // 模拟PluginManager的plugins字典
        pluginManager.plugins[plugin2.identifier] = plugin2
        pluginManager.plugins[plugin3.identifier] = plugin3
        
        do {
            // 由于plugin4是可选依赖，即使缺失也应该验证成功
            try pluginManager.validatePluginDependencies(plugin3)
            XCTAssertTrue(true, "依赖验证应该成功，因为缺失的依赖是可选的")
        } catch {
            XCTFail("依赖验证失败: \(error.localizedDescription)")
        }
    }
    
    // 测试版本比较功能
    func testVersionComparison() {
        let pluginManager = PluginManager.shared
        
        // 测试相等版本
        XCTAssertTrue(pluginManager.isVersion("1.0.0", equalTo: "1.0.0"), "版本1.0.0应该等于1.0.0")
        
        // 测试版本大于
        XCTAssertTrue(pluginManager.isVersion("2.0.0", greaterThan: "1.0.0"), "版本2.0.0应该大于1.0.0")
        XCTAssertTrue(pluginManager.isVersion("1.1.0", greaterThan: "1.0.0"), "版本1.1.0应该大于1.0.0")
        XCTAssertTrue(pluginManager.isVersion("1.0.1", greaterThan: "1.0.0"), "版本1.0.1应该大于1.0.0")
        XCTAssertTrue(pluginManager.isVersion("1.2.3", greaterThan: "1.2.0"), "版本1.2.3应该大于1.2.0")
        
        // 测试版本小于
        XCTAssertTrue(pluginManager.isVersion("1.0.0", lessThan: "2.0.0"), "版本1.0.0应该小于2.0.0")
        XCTAssertTrue(pluginManager.isVersion("1.0.0", lessThan: "1.1.0"), "版本1.0.0应该小于1.1.0")
        XCTAssertTrue(pluginManager.isVersion("1.0.0", lessThan: "1.0.1"), "版本1.0.0应该小于1.0.1")
        
        // 测试版本大于等于
        XCTAssertTrue(pluginManager.isVersion("1.0.0", greaterThanOrEqualTo: "1.0.0"), "版本1.0.0应该大于等于1.0.0")
        XCTAssertTrue(pluginManager.isVersion("1.1.0", greaterThanOrEqualTo: "1.0.0"), "版本1.1.0应该大于等于1.0.0")
        
        // 测试版本小于等于
        XCTAssertTrue(pluginManager.isVersion("1.0.0", lessThanOrEqualTo: "1.0.0"), "版本1.0.0应该小于等于1.0.0")
        XCTAssertTrue(pluginManager.isVersion("1.0.0", lessThanOrEqualTo: "1.1.0"), "版本1.0.0应该小于等于1.1.0")
        
        // 测试不同位数的版本
        XCTAssertTrue(pluginManager.isVersion("1.0", greaterThan: "0.9.9"), "版本1.0应该大于0.9.9")
        XCTAssertTrue(pluginManager.isVersion("1.0.0.0", equalTo: "1.0.0"), "版本1.0.0.0应该等于1.0.0")
        
        // 测试无效版本
        XCTAssertFalse(pluginManager.isVersion("invalid", greaterThan: "1.0.0"), "无效版本应该返回false")
        XCTAssertFalse(pluginManager.isVersion("1.0.0", greaterThan: "invalid"), "与无效版本比较应该返回false")
    }
}
