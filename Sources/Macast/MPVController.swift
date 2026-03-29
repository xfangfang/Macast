import Foundation
import AppKit
import Network

// MPV播放器控制器类
class MPVController {
    
    // MARK: - Properties
    
    // 播放器进程
    private var process: Process?
    // 进程输入管道
    private var inputPipe: FileHandle?
    // 进程输出管道
    private var outputPipe: FileHandle?
    // 进程错误管道
    private var errorPipe: FileHandle?
    
    private var ipcSocketPath: String?
    private var ipcEventConnection: NWConnection?
    private let ipcQueue = DispatchQueue(label: "com.macast.mpv.ipc")
    private var ipcReadBuffer = Data()
    
    // 播放器状态
    var isPlaying: Bool = false
    var isPaused: Bool = false
    var currentTime: Double = 0.0
    var duration: Double = 0.0
    var volume: Int = 50
    var isMuted: Bool = false
    
    // 播放器委托
    weak var delegate: MPVControllerDelegate?
    
    // MARK: - Initialization
    
    init() {
        // 检查MPV是否安装
        guard isMPVInstalled() else {
            print("MPV播放器未安装，请先安装MPV")
            return
        }
    }
    
    deinit {
        // 停止播放器
        stop()
    }
    
    // MARK: - Public Methods
    
    // 加载媒体文件
    func load(url: URL) {
        // 先停止当前播放
        stop()
        
        // 创建新的播放器进程
        process = Process()
        
        // 设置MPV可执行文件路径
        process?.executableURL = URL(fileURLWithPath: "/usr/local/bin/mpv")
        
        // 设置MPV参数
        let ipcPath = buildIPCSocketPath()
        ipcSocketPath = ipcPath
        process?.arguments = [
            "--input-ipc-server=\(ipcPath)",
            "--input-file=-",        // 从标准输入读取命令
            "--no-input-default-bindings",
            "--no-osd-bar",
            "--osd-level=0",
            "--quiet",
            "--idle=yes",            // 启动后保持空闲状态
            "--volume=\(volume)",
            "--mute=\(isMuted ? "yes" : "no")",
            url.absoluteString
        ]
        
        // 设置输入/输出管道
        setupPipes()
        
        // 启动进程
        do {
            try process?.run()
            isPlaying = true
            isPaused = false
            
            // 开始监听输出
            startListeningToOutput()
            startListeningToIPC()
            
            // 通知委托
            delegate?.playerDidLoad(controller: self, url: url)
        } catch {
            print("无法启动MPV播放器: \(error)")
            delegate?.playerDidError(controller: self, error: error)
        }
    }
    
    // 播放
    func play() {
        guard isPaused else {
            return
        }
        
        sendIPCCommand(["set_property", "pause", false], fallbackCommand: "set pause no")
        isPlaying = true
        isPaused = false
        
        // 通知委托
        delegate?.playerDidPlay(controller: self)
    }
    
    // 暂停
    func pause() {
        guard isPlaying && !isPaused else {
            return
        }
        
        sendIPCCommand(["set_property", "pause", true], fallbackCommand: "set pause yes")
        isPlaying = false
        isPaused = true
        
        // 通知委托
        delegate?.playerDidPause(controller: self)
    }
    
    // 停止
    func stop() {
        stopListeningToIPC()
        if process != nil {
            sendIPCCommand(["quit"], fallbackCommand: "quit")
        }
        // 终止进程
        process?.terminate()
        
        // 关闭管道
        inputPipe?.closeFile()
        outputPipe?.closeFile()
        errorPipe?.closeFile()
        
        // 重置状态
        process = nil
        inputPipe = nil
        outputPipe = nil
        errorPipe = nil
        ipcSocketPath = nil
        
        isPlaying = false
        isPaused = false
        currentTime = 0.0
        duration = 0.0
        
        // 通知委托
        delegate?.playerDidStop(controller: self)
    }
    
    // 快进
    func seek(seconds: Double) {
        sendIPCCommand(["seek", seconds, "relative"], fallbackCommand: "seek \(seconds) relative")
        currentTime += seconds
        
        // 通知委托
        delegate?.playerDidSeek(controller: self, time: currentTime)
    }
    
    // 跳到指定时间
    func seek(to time: Double) {
        sendIPCCommand(["seek", time, "absolute"], fallbackCommand: "seek \(time) absolute")
        currentTime = time
        
        // 通知委托
        delegate?.playerDidSeek(controller: self, time: currentTime)
    }
    
    // 设置音量
    func setVolume(volume: Int) {
        // 限制音量范围在0-100之间
        let newVolume = min(max(volume, 0), 100)
        self.volume = newVolume
        
        sendIPCCommand(["set_property", "volume", newVolume], fallbackCommand: "set volume \(newVolume)")
        
        // 通知委托
        delegate?.playerVolumeDidChange(controller: self, volume: newVolume)
    }
    
    // 设置静音
    func setMute(muted: Bool) {
        self.isMuted = muted
        sendIPCCommand(["set_property", "mute", muted], fallbackCommand: "set mute \(muted ? "yes" : "no")")
        
        // 通知委托
        delegate?.playerMuteDidChange(controller: self, muted: muted)
    }
    
    // 全屏
    func toggleFullscreen() {
        sendIPCCommand(["cycle", "fullscreen"], fallbackCommand: "cycle fullscreen")
    }
    
    // MARK: - Private Methods
    
    // 检查MPV是否安装
    private func isMPVInstalled() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["mpv"]
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    // 设置进程管道
    private func setupPipes() {
        // 输入管道
        let inputPipe = Pipe()
        process?.standardInput = inputPipe
        self.inputPipe = inputPipe.fileHandleForWriting
        
        // 输出管道
        let outputPipe = Pipe()
        process?.standardOutput = outputPipe
        self.outputPipe = outputPipe.fileHandleForReading
        
        // 错误管道
        let errorPipe = Pipe()
        process?.standardError = errorPipe
        self.errorPipe = errorPipe.fileHandleForReading
    }
    
    // 发送命令到MPV
    private func sendCommand(_ command: String) {
        guard let inputPipe = inputPipe else {
            return
        }
        
        // 发送命令，以换行符结束
        if let commandData = (command + "\n").data(using: .utf8) {
            inputPipe.write(commandData)
        }
    }
    
    private func buildIPCSocketPath() -> String {
        let id = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("mc-mpv-\(id).sock").path
        try? FileManager.default.removeItem(atPath: path)
        return path
    }
    
    private func sendIPCCommand(_ command: [Any], fallbackCommand: String) {
        guard let ipcSocketPath else {
            sendCommand(fallbackCommand)
            return
        }
        
        let payload: [String: Any] = ["command": command]
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            sendCommand(fallbackCommand)
            return
        }
        
        var message = Data()
        message.append(data)
        message.append(0x0A)
        
        let connection = NWConnection(to: .unix(path: ipcSocketPath), using: .tcp)
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                connection.send(content: message, completion: .contentProcessed { _ in
                    connection.cancel()
                })
            case .failed:
                connection.cancel()
                self?.sendCommand(fallbackCommand)
            default:
                break
            }
        }
        connection.start(queue: ipcQueue)
    }
    
    private func startListeningToIPC() {
        guard let ipcSocketPath else { return }
        connectIPCEventSocket(path: ipcSocketPath, attempt: 0)
    }
    
    private func connectIPCEventSocket(path: String, attempt: Int) {
        if attempt >= 20 { return }
        
        let connection = NWConnection(to: .unix(path: path), using: .tcp)
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.ipcEventConnection = connection
                self?.ipcReadBuffer = Data()
                self?.sendObserveCommands(on: connection)
                self?.receiveIPCData()
            case .failed:
                connection.cancel()
                self?.ipcEventConnection = nil
                self?.ipcQueue.asyncAfter(deadline: .now() + 0.1) {
                    self?.connectIPCEventSocket(path: path, attempt: attempt + 1)
                }
            default:
                break
            }
        }
        
        connection.start(queue: ipcQueue)
    }
    
    private func stopListeningToIPC() {
        ipcEventConnection?.cancel()
        ipcEventConnection = nil
        ipcReadBuffer = Data()
    }
    
    private func sendObserveCommands(on connection: NWConnection) {
        let commands: [[Any]] = [
            ["observe_property", 1, "time-pos"],
            ["observe_property", 2, "duration"],
            ["observe_property", 3, "pause"],
            ["observe_property", 4, "volume"],
            ["observe_property", 5, "mute"]
        ]
        
        for command in commands {
            let payload: [String: Any] = ["command": command]
            guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []) else { continue }
            var message = Data()
            message.append(data)
            message.append(0x0A)
            connection.send(content: message, completion: .contentProcessed { _ in })
        }
    }
    
    private func receiveIPCData() {
        guard let connection = ipcEventConnection else { return }
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] data, _, isComplete, error in
            if let data, !data.isEmpty {
                self?.ipcReadBuffer.append(data)
                self?.drainIPCReadBuffer()
            }
            
            if isComplete || error != nil {
                connection.cancel()
                self?.ipcEventConnection = nil
                return
            }
            
            self?.receiveIPCData()
        }
    }
    
    private func drainIPCReadBuffer() {
        while true {
            guard let newlineIndex = ipcReadBuffer.firstIndex(of: 0x0A) else { return }
            let lineData = ipcReadBuffer.prefix(upTo: newlineIndex)
            ipcReadBuffer.removeSubrange(...newlineIndex)
            handleIPCLine(lineData)
        }
    }
    
    private func handleIPCLine(_ lineData: Data) {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: lineData, options: []),
              let dict = jsonObject as? [String: Any]
        else { return }
        
        if let event = dict["event"] as? String {
            if event == "property-change",
               let name = dict["name"] as? String {
                handleIPCPropertyChange(name: name, data: dict["data"])
            } else if event == "end-file" {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.isPlaying = false
                    self.isPaused = false
                    self.delegate?.playerDidFinish(controller: self)
                }
            }
        }
    }
    
    private func handleIPCPropertyChange(name: String, data: Any?) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            switch name {
            case "time-pos":
                if let value = data as? Double {
                    self.currentTime = value
                }
            case "duration":
                if let value = data as? Double {
                    self.duration = value
                }
            case "pause":
                if let paused = data as? Bool {
                    self.isPaused = paused
                    self.isPlaying = !paused
                    if paused {
                        self.delegate?.playerDidPause(controller: self)
                    } else {
                        self.delegate?.playerDidPlay(controller: self)
                    }
                }
            case "volume":
                if let value = data as? Double {
                    let intValue = Int(value.rounded())
                    self.volume = intValue
                    self.delegate?.playerVolumeDidChange(controller: self, volume: intValue)
                }
            case "mute":
                if let muted = data as? Bool {
                    self.isMuted = muted
                    self.delegate?.playerMuteDidChange(controller: self, muted: muted)
                }
            default:
                break
            }
        }
    }
    
    // 开始监听MPV输出
    private func startListeningToOutput() {
        guard let outputPipe = outputPipe else {
            return
        }
        
        // 设置输出管道的读取通知
        NotificationCenter.default.addObserver(self, 
                                               selector: #selector(handleOutputData(_:)), 
                                               name: FileHandle.readCompletionNotification, 
                                               object: outputPipe)
        
        // 开始异步读取
        outputPipe.readInBackgroundAndNotify()
        
        // 监听错误管道
        guard let errorPipe = errorPipe else {
            return
        }
        
        NotificationCenter.default.addObserver(self, 
                                               selector: #selector(handleErrorData(_:)), 
                                               name: FileHandle.readCompletionNotification, 
                                               object: errorPipe)
        
        errorPipe.readInBackgroundAndNotify()
    }
    
    // 处理MPV输出数据
    @objc private func handleOutputData(_ notification: Notification) {
        guard let outputPipe = notification.object as? FileHandle,
              let data = notification.userInfo?[NSFileHandleNotificationDataItem] as? Data else {
            return
        }
        
        // 解析输出数据
        if let outputString = String(data: data, encoding: .utf8) {
            parseMPVOutput(outputString)
        }
        
        // 继续读取
        outputPipe.readInBackgroundAndNotify()
    }
    
    // 处理MPV错误数据
    @objc private func handleErrorData(_ notification: Notification) {
        guard let errorPipe = notification.object as? FileHandle,
              let data = notification.userInfo?[NSFileHandleNotificationDataItem] as? Data else {
            return
        }
        
        // 解析错误数据
        if let errorString = String(data: data, encoding: .utf8) {
            print("MPV错误: \(errorString)")
        }
        
        // 继续读取
        errorPipe.readInBackgroundAndNotify()
    }
    
    // 解析MPV输出
    private func parseMPVOutput(_ output: String) {
        // 分割输出为多行
        let lines = output.split(separator: "\n")
        
        for line in lines {
            // 解析播放状态
            if line.contains("[playing]") {
                isPlaying = true
                isPaused = false
                
                // 解析时间信息
                if let timeRange = parseTimeRange(from: String(line)) {
                    currentTime = timeRange.current
                    duration = timeRange.duration
                }
                
                // 通知委托
                delegate?.playerDidPlay(controller: self)
            } else if line.contains("[paused]") {
                isPlaying = false
                isPaused = true
                
                // 解析时间信息
                if let timeRange = parseTimeRange(from: String(line)) {
                    currentTime = timeRange.current
                    duration = timeRange.duration
                }
                
                // 通知委托
                delegate?.playerDidPause(controller: self)
            } else if line.contains("Exiting...") {
                // 播放器退出
                stop()
            } else if line.contains("File ended") {
                // 播放结束
                isPlaying = false
                isPaused = false
                currentTime = duration
                
                // 通知委托
                delegate?.playerDidFinish(controller: self)
            }
        }
    }
    
    // 解析时间范围
    private func parseTimeRange(from line: String) -> (current: Double, duration: Double)? {
        // 时间格式: [playing] 00:01:23 / 00:05:45
        let timeRegex = try? NSRegularExpression(pattern: "(\\d{2}):(\\d{2}):(\\d{2}) \\/ (\\d{2}):(\\d{2}):(\\d{2})")
        guard let match = timeRegex?.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count)) else {
            return nil
        }
        
        // 解析当前时间
        let currentHours = Double(parseGroup(in: line, match: match, index: 1)) ?? 0.0
        let currentMinutes = Double(parseGroup(in: line, match: match, index: 2)) ?? 0.0
        let currentSeconds = Double(parseGroup(in: line, match: match, index: 3)) ?? 0.0
        let currentTime = currentHours * 3600 + currentMinutes * 60 + currentSeconds
        
        // 解析总时长
        let durationHours = Double(parseGroup(in: line, match: match, index: 4)) ?? 0.0
        let durationMinutes = Double(parseGroup(in: line, match: match, index: 5)) ?? 0.0
        let durationSeconds = Double(parseGroup(in: line, match: match, index: 6)) ?? 0.0
        let duration = durationHours * 3600 + durationMinutes * 60 + durationSeconds
        
        return (currentTime, duration)
    }
    
    // 解析正则匹配组
    private func parseGroup(in string: String, match: NSTextCheckingResult, index: Int) -> String {
        guard match.numberOfRanges > index else {
            return ""
        }
        
        let range = match.range(at: index)
        guard range.location != NSNotFound else {
            return ""
        }
        
        return String(string[Range(range, in: string)!])
    }
}

// MARK: - MPVControllerDelegate Protocol

protocol MPVControllerDelegate: AnyObject {
    // 播放器加载完成
    func playerDidLoad(controller: MPVController, url: URL)
    
    // 开始播放
    func playerDidPlay(controller: MPVController)
    
    // 暂停播放
    func playerDidPause(controller: MPVController)
    
    // 停止播放
    func playerDidStop(controller: MPVController)
    
    // 播放结束
    func playerDidFinish(controller: MPVController)
    
    // 快进/快退
    func playerDidSeek(controller: MPVController, time: Double)
    
    // 音量变化
    func playerVolumeDidChange(controller: MPVController, volume: Int)
    
    // 静音状态变化
    func playerMuteDidChange(controller: MPVController, muted: Bool)
    
    // 播放错误
    func playerDidError(controller: MPVController, error: Error)
}

// MARK: - MPVControllerDelegate Default Implementation

extension MPVControllerDelegate {
    func playerDidLoad(controller: MPVController, url: URL) {}
    func playerDidPlay(controller: MPVController) {}
    func playerDidPause(controller: MPVController) {}
    func playerDidStop(controller: MPVController) {}
    func playerDidFinish(controller: MPVController) {}
    func playerDidSeek(controller: MPVController, time: Double) {}
    func playerVolumeDidChange(controller: MPVController, volume: Int) {}
    func playerMuteDidChange(controller: MPVController, muted: Bool) {}
    func playerDidError(controller: MPVController, error: Error) {}
}
