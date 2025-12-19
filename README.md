# Audio Device Detection

A Flutter plugin to detect connected audio output devices (Bluetooth, Wired Headset, Built-in Speaker, etc.) and monitor connection state changes on Android and iOS.

## Features

- Get a list of currently connected audio devices (Bluetooth, Wired, Speaker, etc.).
- Listen to real-time audio output connection/disconnection events (Stream).
- Provide device details including name and protocol type (A2DP, HFP, WIRED, SPEAKER, etc.).

## Setup

Before using the plugin, you need to add the necessary permissions for each platform.

### Android

Add the following permissions to your `android/app/src/main/AndroidManifest.xml`. These permissions are required to discover Bluetooth devices and check their connection status.

**Note**: Since this plugin targets Android 12 (API 31) and above, the `BLUETOOTH_CONNECT` permission is mandatory.

```xml
<manifest xmlns:android="[http://schemas.android.com/apk/res/android](http://schemas.android.com/apk/res/android)"
    package="com.example.your_app_name">

    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

    <uses-permission android:name="android.permission.BLUETOOTH"
        android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN"
        android:maxSdkVersion="30" />

    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />

    <application
        ...>
    </application>
</manifest>
```

### iOS

Add the following key to your `ios/Runner/Info.plist`. 
This description will be displayed when the app requests Bluetooth permissions from the user.

```ios/Runner/Info.plist
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Need permission to detect bluetooth audio devices.</string>
```

## Usage

Once the setup is complete, you can use the plugin in your Dart code as follows.

### Requesting Permissions

You must request permission from the user before using the features. We recommend using the `permission_handler` package.

```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermission() async {
final status = await Permission.bluetoothConnect.request();
  if (status.isGranted) {
    print("Bluetooth permission granted.");
  } else {
    print("Bluetooth permission denied.");
  }
}
```

### Get Connected Devices

```dart
import 'package:audio_device_detection/audio_device_detection.dart';

Future<void> getDevices() async {
  List<AudioDevice> devices = await AudioDeviceDetection.instance.getConnectedDevices();
  for (var device in devices) {
    print('Device: ${device.name}, Protocol: ${device.protocol}');
  }
}
```

### Listen to Device Connection Changes

Subscribe to the `onDeviceStateChanged` stream to receive real-time connection and disconnection events.

```dart
import 'dart:async';
import 'package:audio_device_detection/audio_device_detection.dart';

// Variable to manage stream subscription
StreamSubscription<AudioDevice>? deviceStateSubscription;

void listenToDeviceChanges() {
  deviceStateSubscription = AudioDeviceDetection.instance.onDeviceStateChanged.listen((AudioDevice device) {
      if (device.isConnected) {
        print('${device.name} connected. (${device.protocol})');
      } else {
        print('${device.name} disconnected');
      }
  });
}

// Don't forget to cancel the subscription when the widget is disposed.
@override
void dispose() {
  deviceStateSubscription?.cancel();
  super.dispose();
}
```
