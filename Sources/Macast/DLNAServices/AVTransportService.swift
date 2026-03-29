import Foundation

// AVTransport服务类
class AVTransportService: DLNAServiceBase {
    
    // MARK: - Properties
    
    // 媒体信息
    private var currentURI = ""
    private var currentURIMetaData = ""
    internal var currentTransportState = "STOPPED"
    internal var currentTransportStatus = "OK"
    private var currentSpeed = "1"
    internal var currentPosition = "0:00:00"
    private var currentTrackDuration = "0:00:00"
    private var currentTrackMetaData = ""
    private var currentTrackURI = ""
    private var numberOfTracks = "1"
    private var currentTrack = "1"
    
    // MARK: - Initialization
    
    init() {
        super.init(serviceType: .avTransport)
    }
    
    // MARK: - DLNAServiceProtocol Methods
    
    // 处理SOAP动作请求
    override func handleSOAPAction(action: String, parameters: [String: String]) -> Data {
        switch action {
        case "urn:schemas-upnp-org:service:AVTransport:1#SetAVTransportURI":
            return handleSetAVTransportURI(parameters: parameters)
        case "urn:schemas-upnp-org:service:AVTransport:1#GetMediaInfo":
            return handleGetMediaInfo(parameters: parameters)
        case "urn:schemas-upnp-org:service:AVTransport:1#GetTransportInfo":
            return handleGetTransportInfo(parameters: parameters)
        case "urn:schemas-upnp-org:service:AVTransport:1#GetPositionInfo":
            return handleGetPositionInfo(parameters: parameters)
        case "urn:schemas-upnp-org:service:AVTransport:1#GetDeviceCapabilities":
            return handleGetDeviceCapabilities(parameters: parameters)
        case "urn:schemas-upnp-org:service:AVTransport:1#GetTransportSettings":
            return handleGetTransportSettings(parameters: parameters)
        case "urn:schemas-upnp-org:service:AVTransport:1#Stop":
            return handleStop(parameters: parameters)
        case "urn:schemas-upnp-org:service:AVTransport:1#Play":
            return handlePlay(parameters: parameters)
        case "urn:schemas-upnp-org:service:AVTransport:1#Pause":
            return handlePause(parameters: parameters)
        case "urn:schemas-upnp-org:service:AVTransport:1#Seek":
            return handleSeek(parameters: parameters)
        case "urn:schemas-upnp-org:service:AVTransport:1#Next":
            return handleNext(parameters: parameters)
        case "urn:schemas-upnp-org:service:AVTransport:1#Previous":
            return handlePrevious(parameters: parameters)
        case "urn:schemas-upnp-org:service:AVTransport:1#SetNextAVTransportURI":
            return handleSetNextAVTransportURI(parameters: parameters)
        case "urn:schemas-upnp-org:service:AVTransport:1#GetCurrentTransportActions":
            return handleGetCurrentTransportActions(parameters: parameters)
        default:
            return super.handleSOAPAction(action: action, parameters: parameters)
        }
    }
    
    // 获取服务描述XML
    override func getServiceDescription() -> String {
        return "<?xml version=\"1.0\" encoding=\"utf-8\"?><scpd xmlns=\"urn:schemas-upnp-org:service-1-0\">"
            + "<specVersion><major>1</major><minor>0</minor></specVersion>"
            + "<actionList>"
            + "<action><name>SetAVTransportURI</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name>CurrentURI</name><direction>in</direction><relatedStateVariable>CurrentURI</relatedStateVariable></argument><argument><name>CurrentURIMetaData</name><direction>in</direction><relatedStateVariable>CurrentURIMetaData</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>GetMediaInfo</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name NrArgs=\"1\">NrTracks</name><direction>out</direction><relatedStateVariable>NumberOfTracks</relatedStateVariable></argument><argument><name>MediaDuration</name><direction>out</direction><relatedStateVariable>CurrentTrackDuration</relatedStateVariable></argument><argument><name>CurrentURI</name><direction>out</direction><relatedStateVariable>CurrentURI</relatedStateVariable></argument><argument><name>CurrentURIMetaData</name><direction>out</direction><relatedStateVariable>CurrentURIMetaData</relatedStateVariable></argument><argument><name>NextURI</name><direction>out</direction><relatedStateVariable>NextURI</relatedStateVariable></argument><argument><name>NextURIMetaData</name><direction>out</direction><relatedStateVariable>NextURIMetaData</relatedStateVariable></argument><argument><name>PlayMedium</name><direction>out</direction><relatedStateVariable>PlaybackStorageMedium</relatedStateVariable></argument><argument><name>RecordMedium</name><direction>out</direction><relatedStateVariable>RecordStorageMedium</relatedStateVariable></argument><argument><name>WriteStatus</name><direction>out</direction><relatedStateVariable>RecordMediumWriteStatus</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>GetTransportInfo</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name>CurrentTransportState</name><direction>out</direction><relatedStateVariable>TransportState</relatedStateVariable></argument><argument><name>CurrentTransportStatus</name><direction>out</direction><relatedStateVariable>TransportStatus</relatedStateVariable></argument><argument><name>CurrentSpeed</name><direction>out</direction><relatedStateVariable>TransportPlaySpeed</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>GetPositionInfo</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name>Track</name><direction>out</direction><relatedStateVariable>CurrentTrack</relatedStateVariable></argument><argument><name>TrackDuration</name><direction>out</direction><relatedStateVariable>CurrentTrackDuration</relatedStateVariable></argument><argument><name>TrackMetaData</name><direction>out</direction><relatedStateVariable>CurrentTrackMetaData</relatedStateVariable></argument><argument><name>TrackURI</name><direction>out</direction><relatedStateVariable>CurrentTrackURI</relatedStateVariable></argument><argument><name>RelTime</name><direction>out</direction><relatedStateVariable>RelativeTimePosition</relatedStateVariable></argument><argument><name>AbsTime</name><direction>out</direction><relatedStateVariable>AbsoluteTimePosition</relatedStateVariable></argument><argument><name>RelCount</name><direction>out</direction><relatedStateVariable>RelativeCounterPosition</relatedStateVariable></argument><argument><name>AbsCount</name><direction>out</direction><relatedStateVariable>AbsoluteCounterPosition</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>GetDeviceCapabilities</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name>PlayMedia</name><direction>out</direction><relatedStateVariable>PlaybackStorageMedium</relatedStateVariable></argument><argument><name>RecMedia</name><direction>out</direction><relatedStateVariable>RecordStorageMedium</relatedStateVariable></argument><argument><name>RecQualityModes</name><direction>out</direction><relatedStateVariable>RecordQualityModes</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>GetTransportSettings</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name>PlayMode</name><direction>out</direction><relatedStateVariable>CurrentPlayMode</relatedStateVariable></argument><argument><name>RecQualityMode</name><direction>out</direction><relatedStateVariable>CurrentRecordQualityMode</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>Stop</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>Play</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name>Speed</name><direction>in</direction><relatedStateVariable>TransportPlaySpeed</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>Pause</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>Seek</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name>Unit</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_SeekMode</relatedStateVariable></argument><argument><name>Target</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_SeekTarget</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>Next</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>Previous</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>SetNextAVTransportURI</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name>NextURI</name><direction>in</direction><relatedStateVariable>NextURI</relatedStateVariable></argument><argument><name>NextURIMetaData</name><direction>in</direction><relatedStateVariable>NextURIMetaData</relatedStateVariable></argument></argumentList></action>"
            + "<action><name>GetCurrentTransportActions</name><argumentList><argument><name>InstanceID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_InstanceID</relatedStateVariable></argument><argument><name>Actions</name><direction>out</direction><relatedStateVariable>A_ARG_TYPE_ActionList</relatedStateVariable></argument></argumentList></action>"
            + "</actionList>"
            + "<serviceStateTable>"
            + "<stateVariable sendEvents=\"yes\"><name>CurrentURI</name><dataType>string</dataType><defaultValue></defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>CurrentURIMetaData</name><dataType>string</dataType><defaultValue></defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>NextURI</name><dataType>string</dataType><defaultValue></defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>NextURIMetaData</name><dataType>string</dataType><defaultValue></defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>PlaybackStorageMedium</name><dataType>string</dataType><allowedValueList><allowedValue>NETWORK</allowedValue><allowedValue>NONE</allowedValue></allowedValueList></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>RecordStorageMedium</name><dataType>string</dataType><allowedValueList><allowedValue>NONE</allowedValue></allowedValueList></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>RecordMediumWriteStatus</name><dataType>string</dataType><allowedValueList><allowedValue>NOT_IMPLEMENTED</allowedValue></allowedValueList></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>NumberOfTracks</name><dataType>ui4</dataType><defaultValue>1</defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>CurrentTrack</name><dataType>ui4</dataType><defaultValue>1</defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>CurrentTrackDuration</name><dataType>string</dataType><defaultValue>0:00:00</defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>CurrentTrackURI</name><dataType>string</dataType><defaultValue></defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>CurrentTrackMetaData</name><dataType>string</dataType><defaultValue></defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>TransportState</name><dataType>string</dataType><allowedValueList><allowedValue>STOPPED</allowedValue><allowedValue>PLAYING</allowedValue><allowedValue>TRANSITIONING</allowedValue><allowedValue>PAUSED_PLAYBACK</allowedValue></allowedValueList></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>TransportStatus</name><dataType>string</dataType><allowedValueList><allowedValue>OK</allowedValue><allowedValue>ERROR_OCCURRED</allowedValue></allowedValueList></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>TransportPlaySpeed</name><dataType>string</dataType><defaultValue>1</defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>CurrentPlayMode</name><dataType>string</dataType><allowedValueList><allowedValue>NORMAL</allowedValue><allowedValue>REPEAT_ONE</allowedValue><allowedValue>REPEAT_ALL</allowedValue><allowedValue>SHUFFLE</allowedValue><allowedValue>SHUFFLE_NOREPEAT</allowedValue></allowedValueList></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>CurrentRecordQualityMode</name><dataType>string</dataType><allowedValueList><allowedValue>NOT_IMPLEMENTED</allowedValue></allowedValueList></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>RecordQualityModes</name><dataType>string</dataType><defaultValue>NOT_IMPLEMENTED</defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>RelativeTimePosition</name><dataType>string</dataType><defaultValue>0:00:00</defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>AbsoluteTimePosition</name><dataType>string</dataType><defaultValue>NOT_IMPLEMENTED</defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>RelativeCounterPosition</name><dataType>i4</dataType><defaultValue>0</defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"yes\"><name>AbsoluteCounterPosition</name><dataType>i4</dataType><defaultValue>0</defaultValue></stateVariable>"
            + "<stateVariable sendEvents=\"no\"><name>A_ARG_TYPE_InstanceID</name><dataType>ui4</dataType></stateVariable>"
            + "<stateVariable sendEvents=\"no\"><name>A_ARG_TYPE_SeekMode</name><dataType>string</dataType><allowedValueList><allowedValue>REL_TIME</allowedValue></allowedValueList></stateVariable>"
            + "<stateVariable sendEvents=\"no\"><name>A_ARG_TYPE_SeekTarget</name><dataType>string</dataType></stateVariable>"
            + "<stateVariable sendEvents=\"no\"><name>A_ARG_TYPE_ActionList</name><dataType>string</dataType></stateVariable>"
            + "</serviceStateTable>"
            + "</scpd>"
    }
    
    // MARK: - Action Handlers
    
    // 处理SetAVTransportURI动作
    private func handleSetAVTransportURI(parameters: [String: String]) -> Data {
        // 获取参数
        if let uri = parameters["CurrentURI"] {
            currentURI = uri
            currentTrackURI = uri
        }
        
        if let metaData = parameters["CurrentURIMetaData"] {
            currentURIMetaData = metaData
            currentTrackMetaData = metaData
        }
        
        // 更新状态
        currentTransportState = "STOPPED"
        currentTransportStatus = "OK"
        currentPosition = "0:00:00"
        
        print("设置媒体URI: \(currentURI)")
        
        return buildSOAPResponse(action: "SetAVTransportURI", responseParameters: [:])
    }
    
    // 处理GetMediaInfo动作
    private func handleGetMediaInfo(parameters: [String: String]) -> Data {
        return buildSOAPResponse(action: "GetMediaInfo", responseParameters: [
            "NrTracks": numberOfTracks,
            "MediaDuration": currentTrackDuration,
            "CurrentURI": currentURI,
            "CurrentURIMetaData": currentURIMetaData,
            "NextURI": "",
            "NextURIMetaData": "",
            "PlayMedium": "NETWORK",
            "RecordMedium": "NONE",
            "WriteStatus": "NOT_IMPLEMENTED"
        ])
    }
    
    // 处理GetTransportInfo动作
    private func handleGetTransportInfo(parameters: [String: String]) -> Data {
        return buildSOAPResponse(action: "GetTransportInfo", responseParameters: [
            "CurrentTransportState": currentTransportState,
            "CurrentTransportStatus": currentTransportStatus,
            "CurrentSpeed": currentSpeed
        ])
    }
    
    // 处理GetPositionInfo动作
    private func handleGetPositionInfo(parameters: [String: String]) -> Data {
        return buildSOAPResponse(action: "GetPositionInfo", responseParameters: [
            "Track": currentTrack,
            "TrackDuration": currentTrackDuration,
            "TrackMetaData": currentTrackMetaData,
            "TrackURI": currentTrackURI,
            "RelTime": currentPosition,
            "AbsTime": "NOT_IMPLEMENTED",
            "RelCount": "0",
            "AbsCount": "0"
        ])
    }
    
    // 处理GetDeviceCapabilities动作
    private func handleGetDeviceCapabilities(parameters: [String: String]) -> Data {
        return buildSOAPResponse(action: "GetDeviceCapabilities", responseParameters: [
            "PlayMedia": "NETWORK,NONE",
            "RecMedia": "NONE",
            "RecQualityModes": "NOT_IMPLEMENTED"
        ])
    }
    
    // 处理GetTransportSettings动作
    private func handleGetTransportSettings(parameters: [String: String]) -> Data {
        return buildSOAPResponse(action: "GetTransportSettings", responseParameters: [
            "PlayMode": "NORMAL",
            "RecQualityMode": "NOT_IMPLEMENTED"
        ])
    }
    
    // 处理Stop动作
    private func handleStop(parameters: [String: String]) -> Data {
        currentTransportState = "STOPPED"
        currentTransportStatus = "OK"
        currentPosition = "0:00:00"
        
        print("停止播放")
        
        return buildSOAPResponse(action: "Stop", responseParameters: [:])
    }
    
    // 处理Play动作
    private func handlePlay(parameters: [String: String]) -> Data {
        currentTransportState = "PLAYING"
        currentTransportStatus = "OK"
        
        // 检查速度参数
        if let speed = parameters["Speed"] {
            currentSpeed = speed
        }
        
        print("开始播放，速度: \(currentSpeed)")
        
        return buildSOAPResponse(action: "Play", responseParameters: [:])
    }
    
    // 处理Pause动作
    private func handlePause(parameters: [String: String]) -> Data {
        currentTransportState = "PAUSED_PLAYBACK"
        currentTransportStatus = "OK"
        
        print("暂停播放")
        
        return buildSOAPResponse(action: "Pause", responseParameters: [:])
    }
    
    // 处理Seek动作
    private func handleSeek(parameters: [String: String]) -> Data {
        // 获取参数
        if let unit = parameters["Unit"], let target = parameters["Target"] {
            if unit == "REL_TIME" {
                currentPosition = target
                print("快进/快退到: \(target)")
            }
        }
        
        return buildSOAPResponse(action: "Seek", responseParameters: [:])
    }
    
    // 处理Next动作
    private func handleNext(parameters: [String: String]) -> Data {
        // 由于只支持单首歌曲播放，这个动作不做任何处理
        return buildSOAPResponse(action: "Next", responseParameters: [:])
    }
    
    // 处理Previous动作
    private func handlePrevious(parameters: [String: String]) -> Data {
        // 由于只支持单首歌曲播放，这个动作不做任何处理
        return buildSOAPResponse(action: "Previous", responseParameters: [:])
    }
    
    // 处理SetNextAVTransportURI动作
    private func handleSetNextAVTransportURI(parameters: [String: String]) -> Data {
        // 由于只支持单首歌曲播放，这个动作不做任何处理
        return buildSOAPResponse(action: "SetNextAVTransportURI", responseParameters: [:])
    }
    
    // 处理GetCurrentTransportActions动作
    private func handleGetCurrentTransportActions(parameters: [String: String]) -> Data {
        // 根据当前状态返回可用的动作
        var actions: [String]
        
        switch currentTransportState {
        case "STOPPED":
            actions = ["Play", "SetAVTransportURI", "GetMediaInfo", "GetTransportInfo", "GetPositionInfo", "GetDeviceCapabilities", "GetTransportSettings"]
        case "PLAYING":
            actions = ["Pause", "Stop", "Seek", "GetMediaInfo", "GetTransportInfo", "GetPositionInfo", "GetDeviceCapabilities", "GetTransportSettings"]
        case "PAUSED_PLAYBACK":
            actions = ["Play", "Stop", "Seek", "GetMediaInfo", "GetTransportInfo", "GetPositionInfo", "GetDeviceCapabilities", "GetTransportSettings"]
        default:
            actions = ["GetMediaInfo", "GetTransportInfo", "GetPositionInfo", "GetDeviceCapabilities", "GetTransportSettings"]
        }
        
        return buildSOAPResponse(action: "GetCurrentTransportActions", responseParameters: [
            "Actions": actions.joined(separator: ",")
        ])
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
