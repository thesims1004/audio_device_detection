import Foundation
import AVFoundation

class AudioSessionManager {
    private let audioSession = AVAudioSession.sharedInstance()
    private let onDeviceStateChanged: ([String: Any?]) -> Void
    private var lastConnectedDevice: AVAudioSessionPortDescription?

    init(onDeviceStateChanged: @escaping ([String: Any?]) -> Void) {
        self.onDeviceStateChanged = onDeviceStateChanged
        // 초기화 시 현재 활성화된 기기를 한번 체크
        self.lastConnectedDevice = audioSession.currentRoute.outputs.first
    }

    /// 현재 연결된 오디오 출력 장치 목록을 가져옵니다.
    func getCurrentConnectedDevices() -> [[String: Any?]] {
        guard let availableInputs = audioSession.availableInputs else { return [] }

        var devices: [[String: Any?]] = []

        // 1. 현재 활성화된(소리가 나고 있는) 출력 장치
        let currentOutputs = audioSession.currentRoute.outputs
        for port in currentOutputs {
            devices.append(AudioPortMapper.fromAVAudioSessionPort(port, isConnected: true))
        }

        // 2. 현재 활성화되진 않았지만 연결되어 있는 입력 장치들 (블루투스 + 유선) 확인
        // iOS는 '출력 전용' 기기의 전체 목록을 조회하는 API가 제한적이라,
        // 보통 입력(마이크) 기능이 있는 기기들을 통해 연결 여부를 파악합니다.
        let connectedInputs = availableInputs.filter { input in
            // 블루투스이거나, 유선 헤드셋/USB인 경우
            return input.portType.isBluetooth ||
                   input.portType == .headphones ||
                   input.portType == .headsetMic ||
                   input.portType == .usbAudio
        }

        for port in connectedInputs {
            // 이미 출력 목록(currentOutputs)에 추가된 기기는 중복 추가 방지
            if !devices.contains(where: { ($0["address"] as? String) == port.uid }) {
                 devices.append(AudioPortMapper.fromAVAudioSessionPort(port, isConnected: true))
            }
        }

        // 3. 내장 스피커/수화기가 목록에 없다면 강제로 추가 (항상 존재하므로)
        // iOS 정책상 이어폰을 꽂으면 스피커가 리스트에서 사라질 수도 있지만,
        // 물리적으로는 존재하므로 목록에 표시하고 싶다면 아래 로직 추가 가능
        /*
        let hasSpeaker = devices.contains { ($0["protocol"] as? String) == "speaker" }
        if !hasSpeaker {
            devices.append([
                "name": "iPhone Speaker",
                "address": "built_in_speaker",
                "protocol": "speaker",
                "isConnected": true
            ])
        }
        */

        return devices
    }

    /// 오디오 라우트 변경 알림 수신을 시작합니다.
    func startMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    /// 알림 수신을 중지합니다.
    func stopMonitoring() {
        NotificationCenter.default.removeObserver(
            self,
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    /// 라우트 변경 알림을 처리하는 메서드입니다.
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        // 변경 후 현재 활성화된 기기 (보통 스피커 혹은 새로 꽂은 기기)
        let currentDevice = audioSession.currentRoute.outputs.first

        switch reason {
        case .newDeviceAvailable:
            // 새 기기 연결됨
            if let newDevice = currentDevice {
                 // UID 체크로 중복 방지
                if newDevice.uid != lastConnectedDevice?.uid {
                    let deviceMap = AudioPortMapper.fromAVAudioSessionPort(newDevice, isConnected: true)
                    onDeviceStateChanged(deviceMap)
                    lastConnectedDevice = newDevice
                }
            }

        case .oldDeviceUnavailable:
            // 1. 기존 기기 연결 해제 이벤트 전송
            if let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription,
               let oldDevice = previousRoute.outputs.first {
                let oldDeviceMap = AudioPortMapper.fromAVAudioSessionPort(oldDevice, isConnected: false)
                onDeviceStateChanged(oldDeviceMap)
            }

            // 2. 자동으로 전환된 기기(예: 스피커) 정보 전송
            // 유선/블루투스 해제 후 스피커로 돌아왔음을 알리기 위함
            if let fallbackDevice = currentDevice {
                let fallbackMap = AudioPortMapper.fromAVAudioSessionPort(fallbackDevice, isConnected: true)
                onDeviceStateChanged(fallbackMap)
                lastConnectedDevice = fallbackDevice
            }

        case .categoryChange:
            // 카테고리 변경(예: 음악 -> 통화) 시에도 출력 기기가 바뀔 수 있음 (스피커 -> 수화기)
            if let newDevice = currentDevice, newDevice.uid != lastConnectedDevice?.uid {
                let deviceMap = AudioPortMapper.fromAVAudioSessionPort(newDevice, isConnected: true)
                onDeviceStateChanged(deviceMap)
                lastConnectedDevice = newDevice
            }

        default:
            break
        }
    }
}

// AVAudioSession.Port를 확장하여 블루투스 타입인지 쉽게 확인
extension AVAudioSession.Port {
    var isBluetooth: Bool {
        return self == .bluetoothA2DP || self == .bluetoothHFP || self == .bluetoothLE
    }
}
