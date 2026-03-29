import Foundation

// MARK: - MacastPlugin Protocol

/// Macast插件的基本协议
public protocol MacastPlugin: AnyObject {
    
    // MARK: - Basic Properties
    
    /// 插件的唯一标识符
    var identifier: String { get }
    
    /// 插件名称
    var name: String { get }
    
    /// 插件版本
    var version: String { get }
    
    /// 插件描述
    var description: String { get }
    
    /// 插件作者
    var author: String { get }
    
    /// 插件主页
    var homepage: URL? { get }
    
    // MARK: - Plugin State
    
    /// 插件是否已启用
    var isEnabled: Bool { get set }
    
    /// 插件是否已加载
    var isLoaded: Bool { get }
    
    // MARK: - Plugin Dependencies
    
    /// 插件依赖的其他插件
    var dependencies: [PluginDependency] { get }
    
    // MARK: - Lifecycle Methods
    
    /// 初始化插件
    init()
    
    /// 加载插件
    func load() throws
    
    /// 卸载插件
    func unload() throws
    
    /// 启用插件
    func enable() throws
    
    /// 禁用插件
    func disable() throws
    
    /// 插件配置变更
    func configurationChanged()
}

// MARK: - Plugin Lifecycle Events

extension MacastPlugin {
    /// 插件加载完成
    func pluginDidLoad() {
        print("插件已加载: \(name) (\(version))")
    }
    
    /// 插件卸载完成
    func pluginDidUnload() {
        print("插件已卸载: \(name) (\(version))")
    }
    
    /// 插件已启用
    func pluginDidEnable() {
        print("插件已启用: \(name) (\(version))")
    }
    
    /// 插件已禁用
    func pluginDidDisable() {
        print("插件已禁用: \(name) (\(version))")
    }
}

// MARK: - PluginDependency

/// 插件依赖结构
public struct PluginDependency: Codable {
    /// 依赖插件的标识符
    let pluginIdentifier: String
    
    /// 依赖插件的最低版本
    let minimumVersion: String?
    
    /// 依赖是否可选
    let isOptional: Bool
    
    /// 初始化依赖
    public init(pluginIdentifier: String, minimumVersion: String? = nil, isOptional: Bool = false) {
        self.pluginIdentifier = pluginIdentifier
        self.minimumVersion = minimumVersion
        self.isOptional = isOptional
    }
}

// MARK: - MacastPlugin Default Implementation

extension MacastPlugin {
    // 默认实现
    public var homepage: URL? { return nil }
    
    /// 默认不依赖任何插件
    public var dependencies: [PluginDependency] { return [] }
    
    public func load() throws {
        // 默认实现
        pluginDidLoad()
    }
    
    public func unload() throws {
        // 默认实现
        pluginDidUnload()
    }
    
    public func enable() throws {
        // 默认实现
        pluginDidEnable()
    }
    
    public func disable() throws {
        // 默认实现
        pluginDidDisable()
    }
    
    public func configurationChanged() {
        // 默认实现
    }
}
