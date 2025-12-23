import Foundation
import AVFoundation

struct AudioPortMapper {

    /// AVAudioSessionPortDescription을 Dart가 이해할 수 있는 딕셔너리로 변환합니다.
    static func fromAVAudioSessionPort(_ port: AVAudioSessionPortDescription, isConnected: Bool) -> [String: Any?] {
        let protocolName = protocolName(for: port.portType)

        return [
            "name": port.portName,
            "address": port.uid, // iOS에서는 MAC 주소 대신 고유 ID(uid)를 사용
            "protocol": protocolName,
            "isConnected": isConnected
        ]
    }

    /// portType에 따라 프로토콜 이름을 문자열로 반환합니다.
    private static func protocolName(for portType: AVAudioSession.Port) -> String {
        switch portType {
        case .bluetoothA2DP:
            return "bluetooth_a2dp" // 명확한 구분
        case .bluetoothHFP:
            return "bluetooth_hfp"  // 명확한 구분
        case .bluetoothLE:
            return "bluetooth_le"

        case .builtInSpeaker:
            return "speaker"
        case .builtInReceiver:
            return "earpiece"

        case .headphones, .headsetMic, .usbAudio:
            return "wired" // 유선은 통합 유지

        case .carAudio:
            return "bluetooth_hfp" // 차량 오디오는 보통 통화 프로필로 취급하거나 별도 car로 분리

        case .airPlay:
            return "airplay"

        default:
            return "unknown"
        }
    }
}