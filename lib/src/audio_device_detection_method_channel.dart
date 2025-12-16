import 'dart:async';
import 'package:flutter/services.dart';

import 'package:audio_device_detection/models/audio_device.dart';
import 'package:audio_device_detection/src/audio_device_detection_platform_interface.dart';

/// MethodChannel을 사용한 플랫폼 인터페이스의 구체적인 구현체입니다.
class MethodChannelAudioDeviceDetection extends AudioDeviceDetectionPlatform {
  /// Dart와 네이티브 코드 간의 통신을 위한 MethodChannel입니다.
  static const MethodChannel _methodChannel =
  MethodChannel('com.ssgz.audio_device_detection/methods');

  /// 네이티브에서 Dart로 이벤트를 보내기 위한 EventChannel입니다.
  static const EventChannel _eventChannel =
  EventChannel('com.ssgz.audio_device_detection/events');

  Stream<AudioDevice>? _onDeviceStateChanged;

  @override
  Future<List<AudioDevice>> getConnectedDevices() async {
    // 네이티브의 'getConnectedDevices' 메서드를 호출합니다.
    final result = await _methodChannel.invokeMethod<List<dynamic>>('getConnectedDevices');

    if (result == null) {
      return [];
    }

    // 네이티브에서 받은 List<Map>을 List<AudioDevice>로 변환합니다.
    return result
        .map((deviceMap) => AudioDevice.fromMap(Map<String, dynamic>.from(deviceMap)))
        .toList();
  }

  @override
  Stream<AudioDevice> get onDeviceStateChanged {
    _onDeviceStateChanged ??= _eventChannel.receiveBroadcastStream().map(
          (dynamic event) => AudioDevice.fromMap(Map<String, dynamic>.from(event)),
    );
    return _onDeviceStateChanged!;
  }
}