import 'package:flutter_test/flutter_test.dart';
import 'package:audio_device_detection/audio_device_detection.dart';
import 'package:audio_device_detection/src/audio_device_detection_platform_interface.dart';
import 'package:audio_device_detection/audio_device_detection_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAudioDeviceDetectionPlatform
    with MockPlatformInterfaceMixin
    implements AudioDeviceDetectionPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AudioDeviceDetectionPlatform initialPlatform = AudioDeviceDetectionPlatform.instance;

  test('$MethodChannelAudioDeviceDetection is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAudioDeviceDetection>());
  });

  test('getPlatformVersion', () async {
    AudioDeviceDetection audioDeviceDetectionPlugin = AudioDeviceDetection();
    MockAudioDeviceDetectionPlatform fakePlatform = MockAudioDeviceDetectionPlatform();
    AudioDeviceDetectionPlatform.instance = fakePlatform;

    expect(await audioDeviceDetectionPlugin.getPlatformVersion(), '42');
  });
}
