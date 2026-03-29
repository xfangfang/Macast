import Foundation
import Network

// MARK: - PluginMarketplace

/// 插件市场管理器，负责插件的远程获取、安装和更新
class PluginMarketplace: NSObject {
    
    // MARK: - Properties
    
    /// 单例实例
    static let shared = PluginMarketplace()
    
    /// 插件市场服务器地址
    private let marketplaceServerURL = URL(string: "https://macast-plugin-marketplace.example.com")!
    
    /// 已获取的插件列表
    private var availablePlugins: [PluginMarketplaceItem] = []
    
    /// 插件下载队列
    private var downloadQueue: [PluginMarketplaceItem] = []
    
    /// 当前是否正在下载
    private var isDownloading: Bool = false
    
    /// 下载会话
    private lazy var downloadSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// 获取可用插件列表
    func fetchAvailablePlugins(completion: @escaping (Result<[PluginMarketplaceItem], PluginMarketplaceError>) -> Void) {
        // 构建请求URL
        let pluginsURL = marketplaceServerURL.appendingPathComponent("plugins.json")
        
        // 创建请求
        var request = URLRequest(url: pluginsURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // 发送请求
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(.networkError(error.localizedDescription)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.emptyResponse))
                return
            }
            
            do {
                // 解析插件列表
                let plugins = try JSONDecoder().decode([PluginMarketplaceItem].self, from: data)
                self?.availablePlugins = plugins
                completion(.success(plugins))
            } catch {
                completion(.failure(.parseError(error.localizedDescription)))
            }
        }
        
        task.resume()
    }
    
    /// 安装插件
    func installPlugin(_ pluginItem: PluginMarketplaceItem, completion: @escaping (Result<Void, PluginMarketplaceError>) -> Void) {
        // 检查插件是否已经安装
        let pluginManager = PluginManager.shared
        if pluginManager.getPlugin(withIdentifier: pluginItem.identifier) != nil {
            completion(.failure(.alreadyInstalled(pluginItem.name)))
            return
        }
        
        // 下载插件
        downloadPlugin(pluginItem) { result in
            switch result {
            case .success(let pluginBundleURL):
                do {
                    // 安装插件
                    try pluginManager.loadPlugin(at: pluginBundleURL)
                    completion(.success(()))
                } catch {
                    // 清理下载的插件包
                    try? FileManager.default.removeItem(at: pluginBundleURL)
                    completion(.failure(.installationFailed(error.localizedDescription)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// 更新插件
    func updatePlugin(_ pluginItem: PluginMarketplaceItem, completion: @escaping (Result<Void, PluginMarketplaceError>) -> Void) {
        // 检查插件是否已经安装
        let pluginManager = PluginManager.shared
        guard let installedPlugin = pluginManager.getPlugin(withIdentifier: pluginItem.identifier) else {
            completion(.failure(.notInstalled(pluginItem.name)))
            return
        }
        
        // 检查版本是否需要更新
        if !isVersion(pluginItem.version, greaterThan: installedPlugin.version) {
            completion(.failure(.alreadyUpToDate(pluginItem.name)))
            return
        }
        
        // 卸载当前插件
        do {
            try pluginManager.unloadPlugin(withIdentifier: pluginItem.identifier)
            
            // 清理旧插件文件
            if let pluginBundleURL = getPluginBundleURL(for: pluginItem.identifier) {
                try FileManager.default.removeItem(at: pluginBundleURL)
            }
            
            // 下载并安装新插件
            downloadPlugin(pluginItem) { result in
                switch result {
                case .success(let pluginBundleURL):
                    do {
                        try pluginManager.loadPlugin(at: pluginBundleURL)
                        completion(.success(()))
                    } catch {
                        // 清理下载的插件包
                        try? FileManager.default.removeItem(at: pluginBundleURL)
                        completion(.failure(.installationFailed(error.localizedDescription)))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(.updateFailed(error.localizedDescription)))
        }
    }
    
    /// 更新所有插件
    func updateAllPlugins(completion: @escaping (Result<[String: PluginMarketplaceError], PluginMarketplaceError>) -> Void) {
        // 先获取最新的插件列表
        fetchAvailablePlugins { [weak self] result in
            switch result {
            case .success(let plugins):
                // 检查需要更新的插件
                let pluginManager = PluginManager.shared
                var pluginsToUpdate: [PluginMarketplaceItem] = []
                
                for marketplacePlugin in plugins {
                    if let installedPlugin = pluginManager.getPlugin(withIdentifier: marketplacePlugin.identifier) {
                        if self?.isVersion(marketplacePlugin.version, greaterThan: installedPlugin.version) == true {
                            pluginsToUpdate.append(marketplacePlugin)
                        }
                    }
                }
                
                if pluginsToUpdate.isEmpty {
                    completion(.success([:]))
                    return
                }
                
                // 更新插件
                var updateResults: [String: PluginMarketplaceError] = [:]
                var updatedCount = 0
                
                for pluginItem in pluginsToUpdate {
                    self?.updatePlugin(pluginItem) { result in
                        switch result {
                        case .success:
                            break
                        case .failure(let error):
                            updateResults[pluginItem.name] = error
                        }
                        
                        updatedCount += 1
                        if updatedCount == pluginsToUpdate.count {
                            completion(.success(updateResults))
                        }
                    }
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// 卸载插件
    func uninstallPlugin(withIdentifier identifier: String, completion: @escaping (Result<Void, PluginMarketplaceError>) -> Void) {
        let pluginManager = PluginManager.shared
        
        do {
            try pluginManager.unloadPlugin(withIdentifier: identifier)
            
            // 清理插件文件
            if let pluginBundleURL = getPluginBundleURL(for: identifier) {
                try FileManager.default.removeItem(at: pluginBundleURL)
            }
            
            completion(.success(()))
        } catch {
            completion(.failure(.uninstallFailed(error.localizedDescription)))
        }
    }
    
    /// 获取已安装的插件列表
    func getInstalledPlugins() -> [MacastPlugin] {
        return PluginManager.shared.getAllPlugins()
    }
    
    /// 获取已启用的插件列表
    func getEnabledPlugins() -> [MacastPlugin] {
        return PluginManager.shared.getEnabledPlugins()
    }
    
    // MARK: - Private Methods
    
    /// 下载插件
    private func downloadPlugin(_ pluginItem: PluginMarketplaceItem, completion: @escaping (Result<URL, PluginMarketplaceError>) -> Void) {
        // 检查插件是否已在下载队列中
        if downloadQueue.contains(where: { $0.identifier == pluginItem.identifier }) {
            completion(.failure(.alreadyInDownloadQueue(pluginItem.name)))
            return
        }
        
        // 添加到下载队列
        downloadQueue.append(pluginItem)
        
        // 开始处理下载队列
        processDownloadQueue(completion: completion)
    }
    
    /// 处理下载队列
    private func processDownloadQueue(completion: @escaping (Result<URL, PluginMarketplaceError>) -> Void) {
        if isDownloading || downloadQueue.isEmpty {
            return
        }
        
        // 标记开始下载
        isDownloading = true
        
        // 获取队列中的第一个插件
        let pluginItem = downloadQueue.removeFirst()
        
        // 构建下载URL
        let downloadURL = marketplaceServerURL.appendingPathComponent("plugins/pluginItem.identifier).zip")
        
        // 创建下载任务
        let downloadTask = downloadSession.downloadTask(with: downloadURL)
        
        // 关联插件信息到下载任务
        downloadTask.taskDescription = pluginItem.identifier
        
        // 开始下载
        downloadTask.resume()
    }
    
    /// 获取插件包URL
    private func getPluginBundleURL(for identifier: String) -> URL? {
        let pluginDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Macast/Plugins")
        
        return pluginDirectory.appendingPathComponent("identifier).bundle")
    }
    
    /// 解压插件包
    private func unzipPluginPackage(at zipURL: URL, for identifier: String) -> URL? {
        let pluginDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Macast/Plugins")
        
        // 创建临时解压目录
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
            
            // 解压插件包
            // 这里简化处理，实际应该使用更可靠的解压方法
            let destinationURL = pluginDirectory.appendingPathComponent("identifier).bundle")
            
            // 清理旧的插件包
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // 这里应该实现实际的解压逻辑
            // 由于是示例，这里假设解压成功
            try FileManager.default.moveItem(at: zipURL, to: destinationURL)
            
            return destinationURL
        } catch {
            print("解压插件失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 版本比较函数
    private func isVersion(_ version: String, greaterThan otherVersion: String) -> Bool {
        let versionComponents = version.split(separator: ".").map { Int($0) ?? 0 }
        let otherComponents = otherVersion.split(separator: ".").map { Int($0) ?? 0 }
        
        for (v, ov) in zip(versionComponents, otherComponents) {
            if v > ov {
                return true
            } else if v < ov {
                return false
            }
        }
        
        return versionComponents.count > otherComponents.count
    }
    
    private func isVersion(_ version: String, greaterThanOrEqualTo otherVersion: String) -> Bool {
        isVersion(version, greaterThan: otherVersion) || version == otherVersion
    }
}

// MARK: - PluginMarketplaceItem

/// 插件市场中的插件项
struct PluginMarketplaceItem: Codable {
    /// 插件标识符
    let identifier: String
    
    /// 插件名称
    let name: String
    
    /// 插件版本
    let version: String
    
    /// 插件描述
    let description: String
    
    /// 插件作者
    let author: String
    
    /// 插件主页
    let homepage: URL?
    
    /// 插件图标URL
    let iconURL: URL?
    
    /// 插件大小（字节）
    let size: Int64
    
    /// 下载次数
    let downloadCount: Int
    
    /// 评分
    let rating: Double
    
    /// 发布日期
    let releaseDate: Date
    
    /// 最后更新日期
    let lastUpdateDate: Date
    
    /// 插件类型
    let pluginType: PluginType
    
    /// 依赖项
    let dependencies: [PluginDependency]
    
    /// 支持的Macast版本
    let supportedMacastVersion: String
}

// MARK: - PluginType

/// 插件类型枚举
enum PluginType: String, Codable {
    case renderer = "renderer"
    case `protocol` = "protocol"
    case ui = "ui"
    case utility = "utility"
    case other = "other"
}

// MARK: - PluginMarketplaceError

/// 插件市场错误枚举
enum PluginMarketplaceError: Error, LocalizedError {
    case networkError(String)
    case emptyResponse
    case parseError(String)
    case alreadyInstalled(String)
    case notInstalled(String)
    case installationFailed(String)
    case updateFailed(String)
    case alreadyUpToDate(String)
    case uninstallFailed(String)
    case alreadyInDownloadQueue(String)
    case downloadFailed(String)
    case decompressionFailed(String)
    case marketplaceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "网络错误: \(message)"
        case .emptyResponse:
            return "服务器返回空响应"
        case .parseError(let message):
            return "解析响应失败: \(message)"
        case .alreadyInstalled(let pluginName):
            return "插件 \(pluginName) 已安装"
        case .notInstalled(let pluginName):
            return "插件 \(pluginName) 未安装"
        case .installationFailed(let message):
            return "插件安装失败: \(message)"
        case .updateFailed(let message):
            return "插件更新失败: \(message)"
        case .alreadyUpToDate(let pluginName):
            return "插件 \(pluginName) 已是最新版本"
        case .uninstallFailed(let message):
            return "插件卸载失败: \(message)"
        case .alreadyInDownloadQueue(let pluginName):
            return "插件 \(pluginName) 已在下载队列中"
        case .downloadFailed(let message):
            return "插件下载失败: \(message)"
        case .decompressionFailed(let message):
            return "插件解压失败: \(message)"
        case .marketplaceUnavailable:
            return "插件市场不可用"
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension PluginMarketplace: URLSessionDownloadDelegate {
    
    /// 下载完成
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // 获取插件标识符
        guard let pluginIdentifier = downloadTask.taskDescription else {
            isDownloading = false
            processDownloadQueue(completion: { _ in })
            return
        }
        
        // 解压插件
        if let pluginBundleURL = unzipPluginPackage(at: location, for: pluginIdentifier) {
            // 安装插件
            let pluginManager = PluginManager.shared
            do {
                try pluginManager.loadPlugin(at: pluginBundleURL)
            } catch {
                print("插件安装失败: \(error.localizedDescription)")
            }
        } else {
            print("插件解压失败")
        }
        
        // 标记下载完成
        isDownloading = false
        
        // 继续处理队列中的下一个下载
        processDownloadQueue(completion: { _ in })
    }
    
    /// 下载失败
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("插件下载失败: \(error.localizedDescription)")
        }
        
        // 标记下载完成
        isDownloading = false
        
        // 继续处理队列中的下一个下载
        processDownloadQueue(completion: { _ in })
    }
    
    /// 下载进度
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        // 计算下载进度
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        
        // 发送下载进度通知
        NotificationCenter.default.post(name: .pluginMarketplaceDownloadProgress, object: self, userInfo: [
            "identifier": downloadTask.taskDescription ?? "",
            "progress": progress,
            "totalBytesWritten": totalBytesWritten,
            "totalBytesExpectedToWrite": totalBytesExpectedToWrite
        ])
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// 插件市场下载进度通知
    static let pluginMarketplaceDownloadProgress = Notification.Name("com.macast.pluginMarketplace.downloadProgress")
    
    /// 插件市场下载完成通知
    static let pluginMarketplaceDownloadCompleted = Notification.Name("com.macast.pluginMarketplace.downloadCompleted")
    
    /// 插件市场下载失败通知
    static let pluginMarketplaceDownloadFailed = Notification.Name("com.macast.pluginMarketplace.downloadFailed")
}
