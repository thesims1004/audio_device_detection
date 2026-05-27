import 'package:audio_device_detection/src/audio_device_detection_method_channel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audio_device_detection/audio_device_detection.dart';
import 'package:audio_device_detection/src/audio_device_detection_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAudioDeviceDetectionPlatform
    with MockPlatformInterfaceMixin
    implements AudioDeviceDetectionPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<List<AudioDevice>> getConnectedDevices() {
    throw UnimplementedError();
  }

  @override
  Stream<AudioDevice> get onDeviceStateChanged => throw UnimplementedError();
}

void main() {
  final AudioDeviceDetectionPlatform initialPlatform = AudioDeviceDetectionPlatform.instance;

  test('$MethodChannelAudioDeviceDetection is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAudioDeviceDetection>());
  });

  test('getPlatformVersion', () async {
    AudioDeviceDetection audioDeviceDetectionPlugin = AudioDeviceDetection.instance;
    MockAudioDeviceDetectionPlatform fakePlatform = MockAudioDeviceDetectionPlatform();
    AudioDeviceDetectionPlatform.instance = fakePlatform;

    // expect(await audioDeviceDetectionPlugin.getPlatformVersion(), '42');
  });
}
