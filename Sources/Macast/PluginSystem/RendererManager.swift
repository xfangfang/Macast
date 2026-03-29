import Foundation

// MARK: - RendererChangeListener Protocol

/// 渲染器变更监听器协议
public protocol RendererChangeListener: AnyObject {
    /// 渲染器变更时调用
    /// - Parameter renderer: 新的渲染器
    func rendererChanged(_ renderer: DLNARendererProtocol?)
    
    /// 渲染器状态变更时调用
    /// - Parameter renderer: 渲染器
    /// - Parameter state: 新的播放状态
    func rendererStateChanged(_ renderer: DLNARendererProtocol, state: DLNAPlaybackState)
}

// MARK: - RendererManager Class

/// 渲染器管理器类
public class RendererManager {
    /// 单例实例
    public static let shared = RendererManager()
    
    // MARK: - Private Properties
    
    /// 所有可用的渲染器
    private var availableRenderers: [DLNARendererProtocol] = []
    
    /// 当前使用的渲染器
    private var _currentRenderer: DLNARendererProtocol?
    
    /// 渲染器变更监听器
    private var renderersChangeListeners: [RendererChangeListener] = []
    
    // MARK: - Public Properties
    
    /// 当前使用的渲染器
    public var currentRenderer: DLNARendererProtocol? {
        get {
            return _currentRenderer
        }
        set {
            _currentRenderer = newValue
            notifyRendererChanged(newValue)
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // 初始化渲染器管理器
        loadAvailableRenderers()
    }
    
    // MARK: - Renderer Management
    
    /// 加载所有可用的渲染器
    private func loadAvailableRenderers() {
        // 这里应该从插件系统加载所有可用的渲染器
        // 暂时先添加VLC和QuickTime渲染器
        availableRenderers.append(VLCRenderer())
        availableRenderers.append(QuickTimeRenderer())
    }
    
    /// 获取所有可用的渲染器
    public func getAllRenderers() -> [DLNARendererProtocol] {
        return availableRenderers
    }
    
    /// 根据名称获取渲染器
    public func getRendererByName(_ name: String) -> DLNARendererProtocol? {
        return availableRenderers.first { $0.name == name }
    }
    
    /// 设置当前使用的渲染器
    public func setCurrentRenderer(_ renderer: DLNARendererProtocol?) {
        currentRenderer = renderer
    }
    
    /// 根据渲染器ID设置当前使用的渲染器
    public func setCurrentRendererById(_ id: String) {
        currentRenderer = availableRenderers.first { $0.identifier == id }
    }
    
    // MARK: - Renderer Event Handling
    
    /// 添加渲染器变更监听器
    public func addRendererChangeListener(_ listener: RendererChangeListener) {
        if !renderersChangeListeners.contains(where: { $0 === listener }) {
            renderersChangeListeners.append(listener)
        }
    }
    
    /// 移除渲染器变更监听器
    public func removeRendererChangeListener(_ listener: RendererChangeListener) {
        renderersChangeListeners.removeAll { $0 === listener }
    }
    
    /// 通知渲染器变更
    private func notifyRendererChanged(_ renderer: DLNARendererProtocol?) {
        renderersChangeListeners.forEach { $0.rendererChanged(renderer) }
    }
    
    /// 通知渲染器状态变更
    public func notifyRendererStateChanged(_ renderer: DLNARendererProtocol, state: DLNAPlaybackState) {
        renderersChangeListeners.forEach { $0.rendererStateChanged(renderer, state: state) }
    }
}