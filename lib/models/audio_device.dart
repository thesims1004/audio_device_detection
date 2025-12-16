import 'package:flutter/foundation.dart';
import 'package:audio_device_detection/models/audio_protocol.dart';

/// 연결된 오디오 장치의 정보를 담는 불변(immutable) 데이터 클래스입니다.
@immutable
class AudioDevice {
  final String name;
  final AudioProtocol protocol;
  final String? address;
  final bool isConnected;

  const AudioDevice({
    required this.name,
    required this.protocol,
    this.address,
    required this.isConnected,
  });

  factory AudioDevice.fromMap(Map<String, dynamic> map) {
    final String protocolString = map['protocol'] as String? ?? 'unknown';

    AudioProtocol protocol;
    switch (protocolString) {
      case 'bluetooth_a2dp': // 네이티브에서 이 문자열을 보내줘야 함
        protocol = AudioProtocol.bluetoothA2dp;
        break;
      case 'bluetooth_hfp':  // 네이티브에서 이 문자열을 보내줘야 함
        protocol = AudioProtocol.bluetoothHfp;
        break;
      case 'bluetooth_le':
        protocol = AudioProtocol.bluetoothLe;
        break;
      case 'wired':
        protocol = AudioProtocol.wired;
        break;
      case 'speaker':
        protocol = AudioProtocol.speaker;
        break;
      case 'earpiece':
        protocol = AudioProtocol.earpiece;
        break;
      case 'airplay':
        protocol = AudioProtocol.airplay;
        break;
      case 'wifi':
        protocol = AudioProtocol.wifi;
        break;
      default:
      // 혹시 모를 예외나 단순히 "bluetooth"라고만 올 경우를 대비
        if (protocolString.contains('bluetooth')) {
          protocol = AudioProtocol.bluetoothA2dp; // 기본값은 A2DP로 가정
        } else {
          protocol = AudioProtocol.unknown;
        }
    }

    return AudioDevice(
      name: map['name'] as String? ?? 'Unknown',
      protocol: protocol,
      address: map['address'] as String?,
      isConnected: map['isConnected'] as bool? ?? true,
    );
  }

  @override
  String toString() => 'AudioDevice(name: $name, protocol: $protocol, address: $address, isConnected: $isConnected)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AudioDevice &&
        other.name == name &&
        other.protocol == protocol &&
        other.address == address &&
        other.isConnected == other.isConnected;
  }

  @override
  int get hashCode => name.hashCode ^ protocol.hashCode ^ address.hashCode ^ isConnected.hashCode;
}