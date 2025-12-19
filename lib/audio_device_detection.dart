import 'dart:async';

import 'package:audio_device_detection/src/audio_device_detection_platform_interface.dart';
import 'package:audio_device_detection/models/audio_device.dart';

export 'package:audio_device_detection/models/audio_device.dart';
export 'package:audio_device_detection/models/audio_protocol.dart';

/// The main class for detecting and managing audio devices.
///
/// This class provides methods to get the list of currently connected devices
/// and a stream to listen for changes in audio device connections.
class AudioDeviceDetection {
  AudioDeviceDetection._();

  /// A singleton instance of [AudioDeviceDetection].
  static final AudioDeviceDetection instance = AudioDeviceDetection._();

  // 내부적으로 플랫폼 인터페이스를 통해 실제 구현을 호출합니다.
  static AudioDeviceDetectionPlatform get _platform => AudioDeviceDetectionPlatform.instance;

  /// Fetches a list of all currently connected audio output devices.
  ///
  /// This includes Bluetooth devices, wired headsets, and the built-in speaker.
  /// Returns a `Future` that completes with a list of [AudioDevice].
  Future<List<AudioDevice>> getConnectedDevices() => _platform.getConnectedDevices();

  /// 오디오 장치의 연결 상태가 변경될 때마다 이벤트를 발생시키는 스트림입니다.
  ///
  /// 새로운 장치가 연결되거나, 연결이 끊기거나, 활성화된 장치가 변경될 때
  /// 해당 `AudioDevice` 정보를 전달합니다.
  Stream<AudioDevice> get onDeviceStateChanged => _platform.onDeviceStateChanged;
}