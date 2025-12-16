import 'dart:async';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:audio_device_detection/models/audio_device.dart';
import 'package:audio_device_detection/src/audio_device_detection_method_channel.dart';

/// 플러그인과 플랫폼 구현 간의 계약(contract)을 정의하는 추상 클래스입니다.
///
/// 플랫폼 구현체는 이 인터페이스를 상속받아 작성되어야 합니다.
abstract class AudioDeviceDetectionPlatform extends PlatformInterface {
  AudioDeviceDetectionPlatform() : super(token: _token);

  static final Object _token = Object();

  static AudioDeviceDetectionPlatform _instance = MethodChannelAudioDeviceDetection();

  /// 플랫폼 인터페이스의 기본 인스턴스입니다. (초기값: MethodChannel)
  static AudioDeviceDetectionPlatform get instance => _instance;

  /// 플랫폼별 구현을 직접 설정할 수 있습니다.
  /// 주로 테스트 코드에서 Mock 구현을 주입하기 위해 사용됩니다.
  static set instance(AudioDeviceDetectionPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// 현재 연결된 (활성화된) 오디오 장치 목록을 가져옵니다.
  Future<List<AudioDevice>> getConnectedDevices() {
    throw UnimplementedError('getConnectedDevices() has not been implemented.');
  }

  /// 오디오 장치의 연결 상태 변경을 감지하는 이벤트 스트림입니다.
  /// 새로운 장치가 연결되거나 연결이 끊어졌을 때 이벤트를 전달합니다.
  Stream<AudioDevice> get onDeviceStateChanged {
    throw UnimplementedError('onDeviceStateChanged has not been implemented.');
  }
}