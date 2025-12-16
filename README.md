# Audio Device Detection

`audio_device_detection`은 안드로이드와 iOS에서 블루투스, 유선 이어폰, 내장 스피커 등 모든 오디오 출력 장치의 연결 상태 변경을 감지하고, 현재 활성화된 기기 목록을 가져올 수 있는 플러터 플러그인입니다.

## 기능

- 현재 연결된 모든 오디오 기기(블루투스, 유선, 스피커 등) 목록 조회
- 오디오 출력 장치의 연결/해제 및 변경 실시간 감지 (Stream)
- 연결된 기기의 이름과 프로토콜 타입(A2DP, HFP, WIRED, SPEAKER 등) 정보 제공

## 설정 (Setup)

플러그인을 사용하기 전에 각 플랫폼에 맞는 설정을 추가해야 합니다.

### Android

`android/app/src/main/AndroidManifest.xml` 파일에 다음 권한을 추가하세요. 이 권한은 블루투스 기기를 검색하고 연결 상태를 확인하는 데 필요합니다.
**참고**: 이 플러그인은 안드로이드 12 (API 31) 이상을 타겟으로 하므로 `BLUETOOTH_CONNECT` 권한이 필수입니다.

<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
package="com.example.your_app_name">

    <!-- Android 12 (API 31) 이상에서 필요한 블루투스 연결 권한 -->
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

    <!-- Android 11 (API 30) 이하에서 필요한 블루투스 권한 -->
    <uses-permission android:name="android.permission.BLUETOOTH"
        android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN"
        android:maxSdkVersion="30" />

    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />

    <application
        ...>
    </application>
</manifest>

### iOS

`ios/Runner/Info.plist` 파일에 다음 키와 설명을 추가하세요. 이 설명은 앱이 사용자에게 블루투스 권한을 요청할 때 표시됩니다.

<!-- ios/Runner/Info.plist -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>주변의 블루투스 오디오 기기를 찾아 연결 상태를 확인하기 위해 권한이 필요합니다.</string>

## 사용법 (Usage)

플러그인 설정이 완료되면, Dart 코드에서 다음과 같이 사용할 수 있습니다.

### 권한 요청

앱에서 기능을 사용하기 전에 사용자에게 권한을 요청해야 합니다. `permission_handler`와 같은 플러그인을 사용하는 것을 권장합니다.

import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermission() async {
final status = await Permission.bluetoothConnect.request();
if (status.isGranted) {
print("블루투스 권한이 허용되었습니다.");
} else {
print("블루투스 권한이 거부되었습니다.");
}
}

### 현재 연결된 기기 목록 가져오기

import 'package:audio_device_detection/audio_device_detection.dart';

Future<void> getDevices() async {
List<AudioDevice> devices = await AudioDeviceDetection.instance.getConnectedDevices();
for (var device in devices) {
print('Device: ${device.name}, Protocol: ${device.protocol}');
}
}

### 기기 연결 상태 변경 감지하기

`onDeviceStateChanged` 스트림을 구독하여 실시간으로 기기 연결 및 해제 이벤트를 받을 수 있습니다.

import 'dart:async';
import 'package:audio_device_detection/audio_device_detection.dart';

// 스트림 구독을 관리하기 위한 변수
StreamSubscription<AudioDevice>? deviceStateSubscription;

void listenToDeviceChanges() {
deviceStateSubscription = AudioDeviceDetection.instance.onDeviceStateChanged.listen((AudioDevice device) {
if (device.isConnected) {
print('${device.name}이(가) 연결되었습니다.');
} else {
print('${device.name}의 연결이 끊어졌습니다.');
}
});
}

// 위젯이 dispose될 때 구독을 취소하는 것을 잊지 마세요.
@override
void dispose() {
deviceStateSubscription?.cancel();
super.dispose();
}
