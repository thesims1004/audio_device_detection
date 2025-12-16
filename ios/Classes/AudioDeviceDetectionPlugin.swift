import Flutter
import UIKit

public class AudioDeviceDetectionPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var audioSessionManager: AudioSessionManager?

    public static func register(with registrar: FlutterPluginRegistrar) {
        // 1. MethodChannel 설정: Dart -> Native 호출
        let methodChannel = FlutterMethodChannel(name: "com.ssgz.audio_device_detection/methods", binaryMessenger: registrar.messenger())

        // 2. EventChannel 설정: Native -> Dart 이벤트 전송
        let eventChannel = FlutterEventChannel(name: "com.ssgz.audio_device_detection/events", binaryMessenger: registrar.messenger())

        let instance = AudioDeviceDetectionPlugin()

        // 3. 채널 핸들러로 인스턴스 등록
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)

        // 4. 핵심 로직 매니저 초기화 및 콜백 설정
        instance.audioSessionManager = AudioSessionManager { deviceMap in
            // AudioSessionManager에서 상태 변경이 감지되면 이 콜백이 호출됨
            // EventChannel을 통해 Dart로 데이터 전송
            guard let sink = instance.eventSink else { return }
            sink(deviceMap)
        }
    }

    // MethodChannel로부터 호출을 처리하는 메서드
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "getConnectedDevices" {
            // 매니저에 기기 목록 조회를 위임하고 결과를 반환
            let devices = audioSessionManager?.getCurrentConnectedDevices() ?? []
            result(devices)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    // EventChannel 스트림이 시작될 때 호출 (Dart에서 listen)
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        // 오디오 라우트 변경 알림 수신 시작
        audioSessionManager?.startMonitoring()
        return nil
    }

    // EventChannel 스트림이 취소될 때 호출 (Dart에서 cancel)
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        // 알림 수신 중지
        audioSessionManager?.stopMonitoring()
        return nil
    }
}