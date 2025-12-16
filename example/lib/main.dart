import 'dart:async';
import 'dart:io'; // Platform.isAndroid 확인을 위해 추가
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// 개발 중인 플러그인의 메인 파일과 모델을 import 합니다.
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
  // 기기 목록을 저장하고 UI를 업데이트하기 위한 상태 변수
  List<AudioDevice> _connectedDevices = [];
  bool _isLoading = false;
  String _permissionStatus = '권한 상태를 확인하세요.';

  // 이벤트 스트림 구독을 관리하기 위한 변수
  StreamSubscription<AudioDevice>? _deviceStateSubscription;

  // [핵심] Future Queue를 위한 변수
  // 초기값은 완료된 Future로 설정하여 바로 시작할 수 있게 합니다.
  Future<void> _fetchQueue = Future.value();

  @override
  void initState() {
    super.initState();
    // 앱 시작 시 현재 권한 상태를 확인합니다.
    _checkInitialPermission();
  }

  @override
  void dispose() {
    // 위젯이 제거될 때 스트림 구독을 반드시 취소하여 메모리 누수를 방지합니다.
    _deviceStateSubscription?.cancel();
    super.dispose();
  }

  /// 앱 시작 시 현재 권한 상태를 확인하고, 권한이 있다면 바로 기기 목록을 가져옵니다.
  Future<void> _checkInitialPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.bluetoothConnect.status;
      if (status.isGranted) {
        setState(() {
          _permissionStatus = '블루투스 권한이 허용되었습니다.';
        });
        // 권한이 이미 있다면 기기 목록 로드 및 이벤트 리스너 등록
        _initializePlugin();
      } else {
        setState(() {
          _permissionStatus = '블루투스 권한을 요청해야 합니다.';
        });
      }
    } else {
      // iOS는 별도의 권한 요청이 필요 없으므로 바로 초기화 진행
      _initializePlugin();
    }
  }

  /// 블루투스 연결 권한을 요청하는 함수
  Future<void> _requestBluetoothPermission() async {
    if (!Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('iOS에서는 별도의 권한 요청이 필요하지 않습니다.')),
      );
      _initializePlugin();
      return;
    }

    final status = await Permission.bluetoothConnect.request();

    if (status.isGranted) {
      setState(() {
        _permissionStatus = '블루투스 권한이 허용되었습니다.';
      });
      // 권한 획득 성공 시, 기기 목록 로드 및 이벤트 리스너 등록
      _initializePlugin();
    } else if (status.isDenied) {
      setState(() {
        _permissionStatus = '권한이 거부되었습니다. 기능 사용이 제한됩니다.';
      });
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _permissionStatus = '권한이 영구적으로 거부되었습니다. 앱 설정에서 직접 허용해야 합니다.';
      });
      // 설정 화면으로 이동할 수 있는 옵션을 제공
      openAppSettings();
    }
  }

  /// 플러그인 기능(기기 목록, 이벤트 수신)을 초기화하는 함수
  void _initializePlugin() {
    // 이미 구독 중이라면 중복 실행 방지
    if (_deviceStateSubscription != null) return;

    // 1. 현재 연결된 기기 목록 가져오기, 큐에 넣어서 실행
    _scheduleFetchDevices();

    // 2. 기기 연결/해제 이벤트 스트림 구독
    _deviceStateSubscription = AudioDeviceDetection.instance.onDeviceStateChanged.listen(
          (AudioDevice device) {
        // 이벤트 발생 시 스낵바 표시
        final message = device.isConnected
            ? '${device.name}이(가) 연결되었습니다. (${device.protocol.name})'
            : '${device.name}의 연결이 끊어졌습니다.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );

        // 기기 목록을 다시 로드하여 UI 갱신, 큐에 작업 추가
        _scheduleFetchDevices();
      },
      onError: (error) {
        print('이벤트 스트림 에러: $error');
      },
    );
  }

  /// Future Queue 구현
  /// 이전 작업이 무엇이든, 그 작업이 끝난(whenComplete) 뒤에
  /// _fetchConnectedDevices를 실행하도록 체이닝합니다.
  void _scheduleFetchDevices() {
    // 큐(체인)에 새로운 작업을 연결하고, _fetchQueue 포인터를 갱신합니다.
    _fetchQueue = _fetchQueue.whenComplete(() async {

      // OS가 장치 목록을 갱신할 시간을 벌어줍니다.
      // 블루투스 프로필 연결에는 시간이 걸리므로 500ms 정도면 충분히 안전합니다.
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        await _fetchConnectedDevices();
      }
    });
  }

  /// 현재 연결된 기기 목록을 가져와 상태를 업데이트하는 함수
  Future<void> _fetchConnectedDevices() async {
    print('_fetchConnectedDevices called');
    setState(() {
      _isLoading = true;
    });
    try {
      final devices = await AudioDeviceDetection.instance.getConnectedDevices();
      print('_fetchConnectedDevices : ${devices.length}');
      setState(() {
        _connectedDevices = devices;
      });
    } catch (e) {
      print('기기 목록을 가져오는 데 실패했습니다: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
            // 권한 요청 버튼
            ElevatedButton.icon(
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('블루투스 권한 요청 및 초기화'),
              onPressed: _requestBluetoothPermission,
            ),
            const SizedBox(height: 16),
            // 현재 권한 상태 표시
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
                '현재 연결된 오디오 기기',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            // 기기 목록을 표시하는 리스트뷰
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _connectedDevices.isEmpty
                  ? const Center(child: Text('연결된 기기가 없습니다.'))
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
                          '프로토콜: ${device.protocol.name} / 주소: ${device.address ?? 'N/A'}',
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