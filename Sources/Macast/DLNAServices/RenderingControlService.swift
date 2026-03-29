import Foundation

// RenderingControl服务类
class RenderingControlService: DLNAServiceBase {
    
    // MARK: - Properties
    
    // 音频控制参数
    internal var volume: [String: Int] = ["Master": 50]
    internal var mute: [String: Bool] = ["Master": false]
    
    // 视频控制参数
    private var brightness: Int = 100
    private var contrast: Int = 50
    private var sharpness: Int = 50
    private var redGain: Int = 100
    private var greenGain: Int = 100
    private var blueGain: Int = 100
    private var redOffset: Int = 0
    private var greenOffset: Int = 0
    private var blueOffset: Int = 0
    
    // MARK: - Initialization
    
    init() {
        super.init(serviceType: .renderingControl)
    }
    
    // MARK: - DLNAServiceProtocol Methods
    
    // 处理SOAP动作请求
    override func handleSOAPAction(action: String, parameters: [String: String]) -> Data {
        switch action {
        case "urn:schemas-upnp-org:service:RenderingControl:1#GetMute":
            return handleGetMute(parameters: parameters)
        case "urn:schemas-upnp-org:service:RenderingControl:1#SetMute":
            return handleSetMute(parameters: parameters)
        case "urn:schemas-upnp-org:service:RenderingControl:1#GetVolume":
            return handleGetVolume(parameters: parameters)
        case "urn:schemas-upnp-org:service:RenderingControl:1#SetVolume":
            return handleSetVolume(parameters: parameters)
        case "urn:schemas-upnp-org:service:RenderingControl:1#GetBrightness":
            return handleGetBrightness(parameters: parameters)
        case "urn:schemas-upnp-org:service:RenderingControl:1#SetBrightness":
            return handleSetBrightness(parameters: parameters)
        case "urn:schemas-upnp-org:service:RenderingControl:1#GetContrast":
            return handleGetContrast(parameters: parameters)
        case "urn:schemas-upnp-org:service:RenderingControl:1#SetContrast":
            return handleSetContrast(parameters: parameters)
        case "urn:schemas-upnp-org:service:RenderingControl:1#GetSharpness":
            return handleGetSharpness(parameters: parameters)
        case "urn:schemas-upnp-org:service:RenderingControl:1#SetSharpness":
            return handleSetSharpness(parameters: parameters)
        case "urn:schemas-upnp-org:service:RenderingControl:1#GetRGBGain":
            return handleGetRGBGain(parameters: parameters)
        case "urn:schemas-upnp-org:service:RenderingControl:1#SetRGBGain":
            return handleSetRGBGain(parameters: parameters)
        case "urn:schemas-upnp-org:service:RenderingControl:1#GetRGBOffset":
            return handleGetRGBOffset(parameters: parameters)
        case "urn:schemas-upnp-org:service:RenderingControl:1#SetRGBOffset":
            return handleSetRGBOffset(parameters: parameters)
        case "urn:schemas-upnp-org:service:RenderingControl:1#GetWhiteBalance":
            return handleGetWhiteBalance(parameters: parameters)
        case "urn:schemas-upnp-org:service:RenderingControl:1#SelectPreset":
            return handleSelectPreset(parameters: parameters)
        case "urn:schemas-upnp-org:service:RenderingControl:1#ListPresets":
            return handleListPresets(parameters: parameters)
        default:
            return super.handleSOAPAction(action: action, parameters: parameters)
        }
    }
    
    // 获取服务描述XML
    override func getServiceDescription() -> String {
        return "<?xml version=\"1.0\" encoding=\"utf-8\"?><scpd xmlns=\"urn:schemas-upnp-org:service-1-0\">"
            + "<specVersion><major>1</major><minor>0</minor></specVersion>"
            + "<actionList>"
            + "<action><name>ListPresets</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name>PresetNameList</name><direction>out</direction><relatedStateVariable>PresetNameList</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>SelectPreset</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name>PresetName</name><direction>in</direction><relatedStateVariable>PresetNameList</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>GetBrightness</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name>Channel</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_Channel</relatedStateVariable></argument><argument><name>Brightness</name><direction>out</direction><relatedStateVariable>Brightness</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>SetBrightness</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name>Channel</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_Channel</relatedStateVariable></argument><argument><name>Brightness</name><direction>in</direction><relatedStateVariable>Brightness</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>GetContrast</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name>Channel</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_Channel</relatedStateVariable></argument><argument><name>Contrast</name><direction>out</direction><relatedStateVariable>Contrast</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>SetContrast</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name>Channel</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_Channel</relatedStateVariable></argument><argument><name>Contrast</name><direction>in</direction><relatedStateVariable>Contrast</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>GetSharpness</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name>Channel</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_Channel</relatedStateVariable></argument><argument><name>Sharpness</name><direction>out</direction><relatedStateVariable>Sharpness</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>SetSharpness</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name>Channel</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_Channel</relatedStateVariable></argument><argument><name>Sharpness</name><direction>in</direction><relatedStateVariable>Sharpness</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>GetRGBGain</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name>Channel</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_Channel</relatedStateVariable></argument><argument><name>RG Gain</name><direction>out</direction><relatedStateVariable>RedVideoGain</relatedStateVariable></argument><argument><name>GreenVideoGain</name><direction>out</direction><relatedStateVariable>GreenVideoGain</relatedStateVariable></argument><argument><name>BlueVideoGain</name><direction>out</direction><relatedStateVariable>BlueVideoGain</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>SetRGBGain</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name>Channel</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_Channel</relatedStateVariable></argument><argument><name>RedVideoGain</name><direction>in</direction><relatedStateVariable>RedVideoGain</relatedStateVariable></argument><argument><name>GreenVideoGain</name><direction>in</direction><relatedStateVariable>GreenVideoGain</relatedStateVariable></argument><argument><name>BlueVideoGain</name><direction>in</direction><relatedStateVariable>BlueVideoGain</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>GetRGBOffset</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name>Channel</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_Channel</relatedStateVariable></argument><argument><name>RedVideoOffset</name><direction>out</direction><relatedStateVariable>RedVideoOffset</relatedStateVariable></argument><argument><name>GreenVideoOffset</name><direction>out</direction><relatedStateVariable>GreenVideoOffset</relatedStateVariable></argument><argument><name>BlueVideoOffset</name><direction>out</direction><relatedStateVariable>BlueVideoOffset</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>SetRGBOffset</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name>Channel</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_Channel</relatedStateVariable></argument><argument><name>RedVideoOffset</name><direction>in</direction><relatedStateVariable>RedVideoOffset</relatedStateVariable></argument><argument><name>GreenVideoOffset</name><direction>in</direction><relatedStateVariable>GreenVideoOffset</relatedStateVariable></argument><argument><name>BlueVideoOffset</name><direction>in</direction><relatedStateVariable>BlueVideoOffset</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>GetMute</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name>Channel</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_Channel</relatedStateVariable></argument><argument><name>CurrentMute</name><direction>out</direction><relatedStateVariable>Mute</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>SetMute</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name>Channel</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_Channel</relatedStateVariable></argument><argument><name>DesiredMute</name><direction>in</direction><relatedStateVariable>Mute</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>GetVolume</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name>Channel</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_Channel</relatedStateVariable></argument><argument><name>CurrentVolume</name><direction>out</direction><relatedStateVariable>Volume</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>SetVolume</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name>Channel</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_Channel</relatedStateVariable></argument><argument><name>DesiredVolume</name><direction>in</direction><relatedStateVariable>Volume</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>GetWhiteBalance</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name>Channel</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_Channel</relatedStateVariable></argument><argument><name>WhiteBalance</name><direction>out</direction><relatedStateVariable>WhiteBalance</relatedStateVariable></argument></argumentList></action>"
            + "</actionList>"
            + "<serviceStateTable>"
            + "<stateVariable sendEvents=\"yes\"><name>Brightness</name><dataType>ui2</dataType><allowedValueRange><minimum>0</minimum><maximum>100</maximum></allowedValueRange><defaultValue>100</defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>Contrast</name><dataType>ui2</dataType><allowedValueRange><minimum>0</minimum><maximum>100</maximum></allowedValueRange><defaultValue>50</defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>Sharpness</name><dataType>ui2</dataType><allowedValueRange><minimum>0</minimum><maximum>100</maximum></allowedValueRange><defaultValue>50</defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>RedVideoGain</name><dataType>ui2</dataType><allowedValueRange><minimum>0</minimum><maximum>100</maximum></allowedValueRange><defaultValue>100</defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>GreenVideoGain</name><dataType>ui2</dataType><allowedValueRange><minimum>0</minimum><maximum>100</maximum></allowedValueRange><defaultValue>100</defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>BlueVideoGain</name><dataType>ui2</dataType><allowedValueRange><minimum>0</minimum><maximum>100</maximum></allowedValueRange><defaultValue>100</defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>RedVideoOffset</name><dataType>i2</dataType><allowedValueRange><minimum>-100</minimum><maximum>100</maximum></allowedValueRange><defaultValue>0</defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>GreenVideoOffset</name><dataType>i2</dataType><allowedValueRange><minimum>-100</minimum><maximum>100</maximum></allowedValueRange><defaultValue>0</defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>BlueVideoOffset</name><dataType>i2</dataType><allowedValueRange><minimum>-100</minimum><maximum>100</maximum></allowedValueRange><defaultValue>0</defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>Mute</name><dataType>boolean</dataType><defaultValue>0</defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>Volume</name><dataType>ui2</dataType><allowedValueRange><minimum>0</minimum><maximum>100</maximum></allowedValueRange><defaultValue>50</defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>WhiteBalance</name><dataType>string</dataType></stateVariable>"
            + "<stateVariable sendEvents=\"no\"><name>PresetNameList</name><dataType>string</dataType></stateVariable>"
            + "<stateVariable sendEvents=\"no\"><name>A_ARG_TYPE_InstanceID</name><dataType>ui4</dataType></stateVariable>"
            + "<stateVariable sendEvents=\"no\"><name>A_ARG_TYPE_PresetName</name><dataType>string</dataType></stateVariable>"
            + "<stateVariable sendEvents=\"no\"><name>A_ARG_TYPE_Channel</name><dataType>string</dataType><allowedValueList><allowedValue>Master</allowedValue></allowedValueList></stateVariable>"
            + "</serviceStateTable>"
            + "</scpd>"
    }
    
    // MARK: - Action Handlers
    
    // 处理GetMute动作
    private func handleGetMute(parameters: [String: String]) -> Data {
        // 获取参数
        let channel = parameters["Channel"] ?? "Master"
        let isMuted = mute[channel] ?? false
        
        return buildSOAPResponse(action: "GetMute", responseParameters: [
            "CurrentMute": isMuted ? "1" : "0"
        ])
    }
    
    // 处理SetMute动作
    private func handleSetMute(parameters: [String: String]) -> Data {
        // 获取参数
        let channel = parameters["Channel"] ?? "Master"
        let desiredMute = parameters["DesiredMute"] ?? "0"
        let isMuted = desiredMute == "1"
        
        // 更新静音状态
        mute[channel] = isMuted
        
        print("设置\(channel)静音: \(isMuted)")
        
        return buildSOAPResponse(action: "SetMute", responseParameters: [:])
    }
    
    // 处理GetVolume动作
    private func handleGetVolume(parameters: [String: String]) -> Data {
        // 获取参数
        let channel = parameters["Channel"] ?? "Master"
        let currentVolume = volume[channel] ?? 50
        
        return buildSOAPResponse(action: "GetVolume", responseParameters: [
            "CurrentVolume": String(currentVolume)
        ])
    }
    
    // 处理SetVolume动作
    private func handleSetVolume(parameters: [String: String]) -> Data {
        // 获取参数
        let channel = parameters["Channel"] ?? "Master"
        if let desiredVolume = parameters["DesiredVolume"], let volumeValue = Int(desiredVolume) {
            // 限制音量范围在0-100之间
            let newVolume = min(max(volumeValue, 0), 100)
            
            // 更新音量
            volume[channel] = newVolume
            
            print("设置\(channel)音量: \(newVolume)")
        }
        
        return buildSOAPResponse(action: "SetVolume", responseParameters: [:])
    }
    
    // 处理GetBrightness动作
    private func handleGetBrightness(parameters: [String: String]) -> Data {
        return buildSOAPResponse(action: "GetBrightness", responseParameters: [
            "Brightness": String(brightness)
        ])
    }
    
    // 处理SetBrightness动作
    private func handleSetBrightness(parameters: [String: String]) -> Data {
        if let desiredBrightness = parameters["Brightness"], let brightnessValue = Int(desiredBrightness) {
            // 限制亮度范围在0-100之间
            brightness = min(max(brightnessValue, 0), 100)
            print("设置亮度: \(brightness)")
        }
        
        return buildSOAPResponse(action: "SetBrightness", responseParameters: [:])
    }
    
    // 处理GetContrast动作
    private func handleGetContrast(parameters: [String: String]) -> Data {
        return buildSOAPResponse(action: "GetContrast", responseParameters: [
            "Contrast": String(contrast)
        ])
    }
    
    // 处理SetContrast动作
    private func handleSetContrast(parameters: [String: String]) -> Data {
        if let desiredContrast = parameters["Contrast"], let contrastValue = Int(desiredContrast) {
            // 限制对比度范围在0-100之间
            contrast = min(max(contrastValue, 0), 100)
            print("设置对比度: \(contrast)")
        }
        
        return buildSOAPResponse(action: "SetContrast", responseParameters: [:])
    }
    
    // 处理GetSharpness动作
    private func handleGetSharpness(parameters: [String: String]) -> Data {
        return buildSOAPResponse(action: "GetSharpness", responseParameters: [
            "Sharpness": String(sharpness)
        ])
    }
    
    // 处理SetSharpness动作
    private func handleSetSharpness(parameters: [String: String]) -> Data {
        if let desiredSharpness = parameters["Sharpness"], let sharpnessValue = Int(desiredSharpness) {
            // 限制清晰度范围在0-100之间
            sharpness = min(max(sharpnessValue, 0), 100)
            print("设置清晰度: \(sharpness)")
        }
        
        return buildSOAPResponse(action: "SetSharpness", responseParameters: [:])
    }
    
    // 处理GetRGBGain动作
    private func handleGetRGBGain(parameters: [String: String]) -> Data {
        return buildSOAPResponse(action: "GetRGBGain", responseParameters: [
            "RedVideoGain": String(redGain),
            "GreenVideoGain": String(greenGain),
            "BlueVideoGain": String(blueGain)
        ])
    }
    
    // 处理SetRGBGain动作
    private func handleSetRGBGain(parameters: [String: String]) -> Data {
        if let redGainStr = parameters["RedVideoGain"], let redGainValue = Int(redGainStr) {
            redGain = min(max(redGainValue, 0), 100)
        }
        
        if let greenGainStr = parameters["GreenVideoGain"], let greenGainValue = Int(greenGainStr) {
            greenGain = min(max(greenGainValue, 0), 100)
        }
        
        if let blueGainStr = parameters["BlueVideoGain"], let blueGainValue = Int(blueGainStr) {
            blueGain = min(max(blueGainValue, 0), 100)
        }
        
        print("设置RGB增益: R=\(redGain), G=\(greenGain), B=\(blueGain)")
        
        return buildSOAPResponse(action: "SetRGBGain", responseParameters: [:])
    }
    
    // 处理GetRGBOffset动作
    private func handleGetRGBOffset(parameters: [String: String]) -> Data {
        return buildSOAPResponse(action: "GetRGBOffset", responseParameters: [
            "RedVideoOffset": String(redOffset),
            "GreenVideoOffset": String(greenOffset),
            "BlueVideoOffset": String(blueOffset)
        ])
    }
    
    // 处理SetRGBOffset动作
    private func handleSetRGBOffset(parameters: [String: String]) -> Data {
        if let redOffsetStr = parameters["RedVideoOffset"], let redOffsetValue = Int(redOffsetStr) {
            redOffset = min(max(redOffsetValue, -100), 100)
        }
        
        if let greenOffsetStr = parameters["GreenVideoOffset"], let greenOffsetValue = Int(greenOffsetStr) {
            greenOffset = min(max(greenOffsetValue, -100), 100)
        }
        
        if let blueOffsetStr = parameters["BlueVideoOffset"], let blueOffsetValue = Int(blueOffsetStr) {
            blueOffset = min(max(blueOffsetValue, -100), 100)
        }
        
        print("设置RGB偏移: R=\(redOffset), G=\(greenOffset), B=\(blueOffset)")
        
        return buildSOAPResponse(action: "SetRGBOffset", responseParameters: [:])
    }
    
    // 处理GetWhiteBalance动作
    private func handleGetWhiteBalance(parameters: [String: String]) -> Data {
        return buildSOAPResponse(action: "GetWhiteBalance", responseParameters: [
            "WhiteBalance": "Normal"
        ])
    }
    
    // 处理ListPresets动作
    private func handleListPresets(parameters: [String: String]) -> Data {
        return buildSOAPResponse(action: "ListPresets", responseParameters: [
            "PresetNameList": ""
        ])
    }
    
    // 处理SelectPreset动作
    private func handleSelectPreset(parameters: [String: String]) -> Data {
        // 不支持预设，返回空响应
        return buildSOAPResponse(action: "SelectPreset", responseParameters: [:])
    }
    
    // MARK: - Helper Methods
    
    // 构建SOAP错误响应
    private func buildSOAPErrorResponse(code: String, description: String) -> Data {
        let response = "<?xml version=\"1.0\" encoding=\"utf-8\"?><s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\" s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">"
            + "<s:Body><s:Fault><faultcode>s:Client</faultcode><faultstring>UPnPError</faultstring>"
            + "<detail><UPnPError xmlns=\"urn:schemas-upnp-org:control-1-0\"><errorCode>\(code)</errorCode><errorDescription>\(description)</errorDescription></UPnPError></detail></s:Fault></s:Body></s:Envelope>"
        
        return response.data(using: .utf8) ?? Data()
    }
}
