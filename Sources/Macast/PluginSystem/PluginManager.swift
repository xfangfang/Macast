import Foundation

// MARK: - PluginManager

/// 插件管理器，负责插件的加载、卸载、启用和禁用等操作
class PluginManager {
    
    // MARK: - Properties
    
    /// 单例实例
    static let shared = PluginManager()
    
    /// 已加载的插件
    var plugins: [String: MacastPlugin] = [:]
    
    /// 插件目录
    private let pluginDirectory: URL
    
    /// 插件配置
    private var pluginConfigurations: [String: PluginConfiguration] = [:]
    
    // MARK: - Initialization
    
    private init() {
        // 设置插件目录
        let applicationSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        pluginDirectory = applicationSupportDirectory.appendingPathComponent("Macast/Plugins")
        
        // 创建插件目录（如果不存在）
        createPluginDirectoryIfNeeded()
        
        // 加载插件配置
        loadPluginConfigurations()
    }
    
    // MARK: - Public Methods
    
    /// 加载所有插件
    func loadAllPlugins() {
        do {
            // 获取插件目录中的所有插件
            let pluginBundles = try FileManager.default.contentsOfDirectory(at: pluginDirectory, includingPropertiesForKeys: nil)
            
            // 加载每个插件
            for bundleURL in pluginBundles {
                try loadPlugin(at: bundleURL)
            }
            
            print("已加载 \(plugins.count) 个插件")
        } catch {
            print("加载插件失败: \(error.localizedDescription)")
        }
    }
    
    /// 加载指定路径的插件
    func loadPlugin(at bundleURL: URL) throws {
        // 检查是否是有效的插件包
        guard bundleURL.pathExtension == "bundle" else {
            throw PluginError.invalidBundle
        }
        
        // 加载插件包
        let bundle = Bundle(url: bundleURL)
        guard let bundle = bundle else {
            throw PluginError.loadFailed
        }
        
        // 获取插件主类
        guard let pluginClassName = bundle.infoDictionary?["MacastPluginPrincipalClass"] as? String else {
            throw PluginError.missingPrincipalClass
        }
        
        // 实例化插件
        guard let pluginClass = bundle.classNamed(pluginClassName) as? MacastPlugin.Type else {
            throw PluginError.invalidPrincipalClass
        }
        
        // 创建插件实例
        let plugin = pluginClass.init()
        
        // 检查插件依赖
        try validatePluginDependencies(plugin)
        
        // 加载插件
        try plugin.load()
        
        // 根据配置启用或禁用插件
        if let configuration = pluginConfigurations[plugin.identifier] {
            plugin.isEnabled = configuration.isEnabled
        } else {
            // 默认启用插件
            plugin.isEnabled = true
            
            // 保存默认配置
            let configuration = PluginConfiguration(identifier: plugin.identifier, isEnabled: true)
            pluginConfigurations[plugin.identifier] = configuration
            savePluginConfigurations()
        }
        
        // 将插件添加到已加载的插件列表
        plugins[plugin.identifier] = plugin
        
        print("已加载插件: \(plugin.name) (\(plugin.version))")
    }
    
    /// 卸载指定标识符的插件
    func unloadPlugin(withIdentifier identifier: String) throws {
        guard let plugin = plugins[identifier] else {
            throw PluginError.pluginNotFound
        }
        
        // 卸载插件
        try plugin.unload()
        
        // 从已加载的插件列表中移除
        plugins.removeValue(forKey: identifier)
        
        print("已卸载插件: \(plugin.name) (\(plugin.version))")
    }
    
    /// 卸载所有插件
    func unloadAllPlugins() {
        for (identifier, plugin) in plugins {
            do {
                try unloadPlugin(withIdentifier: identifier)
            } catch {
                print("卸载插件失败: \(plugin.name) - \(error.localizedDescription)")
            }
        }
    }
    
    /// 启用指定标识符的插件
    func enablePlugin(withIdentifier identifier: String) throws {
        guard let plugin = plugins[identifier] else {
            throw PluginError.pluginNotFound
        }
        
        // 启用插件
        try plugin.enable()
        plugin.isEnabled = true
        
        // 更新配置
        if var configuration = pluginConfigurations[identifier] {
            configuration.isEnabled = true
            pluginConfigurations[identifier] = configuration
            savePluginConfigurations()
        }
    }
    
    /// 禁用指定标识符的插件
    func disablePlugin(withIdentifier identifier: String) throws {
        guard let plugin = plugins[identifier] else {
            throw PluginError.pluginNotFound
        }
        
        // 禁用插件
        try plugin.disable()
        plugin.isEnabled = false
        
        // 更新配置
        if var configuration = pluginConfigurations[identifier] {
            configuration.isEnabled = false
            pluginConfigurations[identifier] = configuration
            savePluginConfigurations()
        }
    }
    
    /// 获取所有已加载的插件
    func getAllPlugins() -> [MacastPlugin] {
        return Array(plugins.values)
    }
    
    /// 获取指定标识符的插件
    func getPlugin(withIdentifier identifier: String) -> MacastPlugin? {
        return plugins[identifier]
    }
    
    /// 获取所有已启用的插件
    func getEnabledPlugins() -> [MacastPlugin] {
        return plugins.values.filter { $0.isEnabled }
    }
    
    // MARK: - Private Methods
    
    /// 创建插件目录（如果不存在）
    private func createPluginDirectoryIfNeeded() {
        do {
            try FileManager.default.createDirectory(at: pluginDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("创建插件目录失败: \(error.localizedDescription)")
        }
    }
    
    /// 加载插件配置
    private func loadPluginConfigurations() {
        let configurationFileURL = pluginDirectory.appendingPathComponent("plugin_configurations.plist")
        
        if FileManager.default.fileExists(atPath: configurationFileURL.path) {
            do {
                let data = try Data(contentsOf: configurationFileURL)
                let configurations = try PropertyListDecoder().decode([String: PluginConfiguration].self, from: data)
                pluginConfigurations = configurations
            } catch {
                print("加载插件配置失败: \(error.localizedDescription)")
            }
        }
    }
    
    /// 保存插件配置
    private func savePluginConfigurations() {
        let configurationFileURL = pluginDirectory.appendingPathComponent("plugin_configurations.plist")
        
        do {
            let data = try PropertyListEncoder().encode(pluginConfigurations)
            try data.write(to: configurationFileURL, options: .atomic)
        } catch {
            print("保存插件配置失败: \(error.localizedDescription)")
        }
    }
    
    /// 验证插件依赖
    func validatePluginDependencies(_ plugin: MacastPlugin) throws {
        for dependency in plugin.dependencies {
            // 检查依赖是否已加载
            if let loadedDependency = plugins[dependency.pluginIdentifier] {
                // 检查版本要求
                if let minVersion = dependency.minimumVersion {
                    if !isVersion(loadedDependency.version, greaterThanOrEqualTo: minVersion) {
                        throw PluginError.dependencyVersionMismatch(
                            pluginName: plugin.name,
                            dependencyName: loadedDependency.name,
                            requiredVersion: minVersion,
                            actualVersion: loadedDependency.version
                        )
                    }
                }
            } else {
                // 检查依赖是否在插件目录中可用
                let dependencyAvailable = checkIfDependencyAvailable(dependency.pluginIdentifier)
                
                if !dependencyAvailable && !dependency.isOptional {
                    throw PluginError.missingDependency(
                        pluginName: plugin.name,
                        dependencyIdentifier: dependency.pluginIdentifier
                    )
                }
            }
        }
    }
    
    /// 检查依赖插件是否在插件目录中可用
    private func checkIfDependencyAvailable(_ dependencyIdentifier: String) -> Bool {
        do {
            // 检查插件目录中是否有匹配的插件包
            let pluginBundles = try FileManager.default.contentsOfDirectory(at: pluginDirectory, includingPropertiesForKeys: nil)
            
            for bundleURL in pluginBundles {
                if bundleURL.pathExtension == "bundle" {
                    if let bundle = Bundle(url: bundleURL),
                       let pluginInfo = bundle.infoDictionary,
                       let pluginIdentifier = pluginInfo["MacastPluginIdentifier"] as? String {
                        
                        if pluginIdentifier == dependencyIdentifier {
                            return true
                        }
                    }
                }
            }
        } catch {
            print("检查插件依赖失败: \(error.localizedDescription)")
        }
        
        return false
    }
    
    /// 版本比较函数
    func isVersion(_ version: String, greaterThanOrEqualTo minVersion: String) -> Bool {
        guard let result = compareVersion(version, minVersion) else { return false }
        return result != .orderedAscending
    }
    
    func isVersion(_ version: String, greaterThan other: String) -> Bool {
        guard let result = compareVersion(version, other) else { return false }
        return result == .orderedDescending
    }
    
    func isVersion(_ version: String, lessThan other: String) -> Bool {
        guard let result = compareVersion(version, other) else { return false }
        return result == .orderedAscending
    }
    
    func isVersion(_ version: String, lessThanOrEqualTo other: String) -> Bool {
        guard let result = compareVersion(version, other) else { return false }
        return result != .orderedDescending
    }
    
    func isVersion(_ version: String, equalTo other: String) -> Bool {
        guard let result = compareVersion(version, other) else { return false }
        return result == .orderedSame
    }
    
    private func compareVersion(_ a: String, _ b: String) -> ComparisonResult? {
        guard let aParts = parseVersion(a), let bParts = parseVersion(b) else { return nil }
        let maxCount = max(aParts.count, bParts.count)
        let paddedA = aParts + Array(repeating: 0, count: max(0, maxCount - aParts.count))
        let paddedB = bParts + Array(repeating: 0, count: max(0, maxCount - bParts.count))
        
        for (x, y) in zip(paddedA, paddedB) {
            if x < y { return .orderedAscending }
            if x > y { return .orderedDescending }
        }
        return .orderedSame
    }
    
    private func parseVersion(_ version: String) -> [Int]? {
        let parts = version.split(separator: ".")
        guard !parts.isEmpty else { return nil }
        var result: [Int] = []
        result.reserveCapacity(parts.count)
        for part in parts {
            guard let value = Int(part) else { return nil }
            result.append(value)
        }
        return result
    }
}

// MARK: - PluginConfiguration

/// 插件配置
struct PluginConfiguration: Codable {
    var identifier: String
    var isEnabled: Bool
}

// MARK: - PluginError

enum PluginError: Error, LocalizedError {
    case invalidBundle
    case loadFailed
    case missingPrincipalClass
    case invalidPrincipalClass
    case pluginNotFound
    case pluginAlreadyLoaded
    case missingDependency(pluginName: String, dependencyIdentifier: String)
    case dependencyVersionMismatch(pluginName: String, dependencyName: String, requiredVersion: String, actualVersion: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidBundle:
            return "无效的插件包"
        case .loadFailed:
            return "插件加载失败"
        case .missingPrincipalClass:
            return "缺少插件主类"
        case .invalidPrincipalClass:
            return "无效的插件主类"
        case .pluginNotFound:
            return "插件未找到"
        case .pluginAlreadyLoaded:
            return "插件已加载"
        case .missingDependency(let pluginName, let dependencyIdentifier):
            return "插件 \(pluginName) 缺少依赖: \(dependencyIdentifier)"
        case .dependencyVersionMismatch(let pluginName, let dependencyName, let requiredVersion, let actualVersion):
            return "插件 \(pluginName) 依赖版本不匹配: \(dependencyName) 需要 \(requiredVersion)，实际版本 \(actualVersion)"
        }
    }
}
