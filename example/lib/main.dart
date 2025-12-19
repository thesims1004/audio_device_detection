import 'dart:async';
import 'dart:io'; // Added to check Platform.isAndroid
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// Import the main file and models from the plugin we are developing.
import 'package:audio_device_detection/audio_device_detection.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Device Detection Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // State variables to store the device list and update the UI.
  List<AudioDevice> _connectedDevices = [];
  bool _isLoading = false;
  String _permissionStatus = 'Please check the permission status.';

  // Variable to manage the event stream subscription.
  StreamSubscription<AudioDevice>? _deviceStateSubscription;

  // [Key] Variable for the Future Queue.
  // Initialized with a completed Future to allow immediate execution.
  Future<void> _fetchQueue = Future.value();

  @override
  void initState() {
    super.initState();
    // Check the current permission status when the app starts.
    _checkInitialPermission();
  }

  @override
  void dispose() {
    // It's crucial to cancel the stream subscription when the widget is disposed to prevent memory leaks.
    _deviceStateSubscription?.cancel();
    super.dispose();
  }

  /// Checks the current permission status at app startup and loads the device list if permission is granted.
  Future<void> _checkInitialPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.bluetoothConnect.status;
      if (status.isGranted) {
        setState(() {
          _permissionStatus = 'Bluetooth permission has been granted.';
        });
        // If permission is already granted, load the device list and register the event listener.
        _initializePlugin();
      } else {
        setState(() {
          _permissionStatus = 'Bluetooth permission needs to be requested.';
        });
      }
    } else {
      // iOS does not require a separate permission request, so proceed with initialization.
      setState(() {
        _permissionStatus = 'Ready to detect devices on iOS.';
      });
      _initializePlugin();
    }
  }

  /// A function to request Bluetooth connection permission.
  Future<void> _requestBluetoothPermission() async {
    if (!Platform.isAndroid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No separate permission request is needed on iOS.')),
        );
      }
      _initializePlugin();
      return;
    }

    final status = await Permission.bluetoothConnect.request();

    if (status.isGranted) {
      setState(() {
        _permissionStatus = 'Bluetooth permission has been granted.';
      });
      // On successful permission grant, load the device list and register the event listener.
      _initializePlugin();
    } else if (status.isDenied) {
      setState(() {
        _permissionStatus = 'Permission denied. Feature usage is limited.';
      });
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _permissionStatus = 'Permission permanently denied. You must grant it from the app settings.';
      });
      // Provide an option to navigate to the app settings.
      openAppSettings();
    }
  }

  /// Initializes the plugin's features (device list, event stream).
  void _initializePlugin() {
    // Prevent duplicate subscriptions.
    if (_deviceStateSubscription != null) return;

    // 1. Fetch the initial list of connected devices by scheduling it in the queue.
    _scheduleFetchDevices();

    // 2. Subscribe to the device connection/disconnection event stream.
    _deviceStateSubscription = AudioDeviceDetection.instance.onDeviceStateChanged.listen(
          (AudioDevice device) {
        // Show a SnackBar when an event occurs.
        final message = device.isConnected
            ? '${device.name} has been connected. (${device.protocol.name})'
            : '${device.name} has been disconnected.';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Schedule a device list refresh to update the UI.
        _scheduleFetchDevices();
      },
      onError: (error) {
        print('Event stream error: $error');
      },
    );
  }

  /// Future Queue Implementation.
  /// Chains the _fetchConnectedDevices call to run after the previous task is complete.
  void _scheduleFetchDevices() {
    // Chains a new task to the queue and updates the _fetchQueue pointer.
    _fetchQueue = _fetchQueue.whenComplete(() async {
      // Give the OS some time to update the device list.
      // A delay of 500ms is generally safe for Bluetooth profile connections to settle.
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        await _fetchConnectedDevices();
      }
    });
  }

  /// Fetches the list of connected devices and updates the state.
  Future<void> _fetchConnectedDevices() async {
    print('_fetchConnectedDevices called');
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final devices = await AudioDeviceDetection.instance.getConnectedDevices();
      print('_fetchConnectedDevices found: ${devices.length}');
      if (mounted) {
        setState(() {
          _connectedDevices = devices;
        });
      }
    } catch (e) {
      print('Failed to get device list: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Device Detection Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Permission request button
            ElevatedButton.icon(
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Request Permission & Initialize'),
              onPressed: _requestBluetoothPermission,
            ),
            const SizedBox(height: 16),
            // Display current permission status
            Text(
              _permissionStatus,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Currently Connected Audio Devices',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            // ListView to display the device list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _connectedDevices.isEmpty
                  ? const Center(child: Text('No connected devices found.'))
                  : RefreshIndicator(
                onRefresh: _fetchConnectedDevices,
                child: ListView.builder(
                  itemCount: _connectedDevices.length,
                  itemBuilder: (context, index) {
                    final device = _connectedDevices[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.headset, color: Colors.blue),
                        title: Text(device.name),
                        subtitle: Text(
                          'Protocol: ${device.protocol.name.toUpperCase()} / ID: ${device.address ?? 'N/A'}',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}