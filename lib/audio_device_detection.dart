import 'dart:async';

import 'package:audio_device_detection/src/audio_device_detection_platform_interface.dart';
import 'package:audio_device_detection/models/audio_device.dart';
import 'package:audio_device_detection/models/audio_protocol.dart';

// 모델 파일을 export하여 개발자가 쉽게 import할 수 있도록 합니다.
export 'package:audio_device_detection/models/audio_device.dart';
export 'package:audio_device_detection/models/audio_protocol.dart';

class AudioDeviceDetection {
  AudioDeviceDetection._();

  /// `AudioDeviceDetection`의 싱글턴 인스턴스입니다.
  static final AudioDeviceDetection instance = AudioDeviceDetection._();

  // 내부적으로 플랫폼 인터페이스를 통해 실제 구현을 호출합니다.
  static AudioDeviceDetectionPlatform get _platform => AudioDeviceDetectionPlatform.instance;

  /// 현재 시스템에 연결되어 활성화된 오디오 장치 목록을 비동기적으로 가져옵니다.
  ///
  /// 블루투스 이어폰, 내장 스피커 등 사용 가능한 모든 오디오 출력 장치를 반환합니다.
  Future<List<AudioDevice>> getConnectedDevices() => _platform.getConnectedDevices();

  /// 오디오 장치의 연결 상태가 변경될 때마다 이벤트를 발생시키는 스트림입니다.
  ///
  /// 새로운 장치가 연결되거나, 연결이 끊기거나, 활성화된 장치가 변경될 때
  /// 해당 `AudioDevice` 정보를 전달합니다.
  Stream<AudioDevice> get onDeviceStateChanged => _platform.onDeviceStateChanged;
}