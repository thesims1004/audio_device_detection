package com.ssgz.audio_device_detection

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
/** AudioDeviceDetectionPlugin */
class AudioDeviceDetectionPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    // 핵심 로직을 처리할 매니저
    private lateinit var audioDeviceManager: AudioDeviceManager

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        val context = flutterPluginBinding.applicationContext

        // 1. MethodChannel 설정: Dart -> Native 호출
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.ssgz.audio_device_detection/methods")
        methodChannel.setMethodCallHandler(this)

        // 2. EventChannel 설정: Native -> Dart 이벤트 전송
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.ssgz.audio_device_detection/events")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        // 3. 핵심 로직 매니저 초기화 및 콜백 설정
        audioDeviceManager = AudioDeviceManager(context) { deviceMap ->
            // AudioDeviceManager에서 상태 변경이 감지되면 이 콜백이 호출됨
            // EventChannel을 통해 Dart로 데이터 전송
            eventSink?.success(deviceMap)
        }
        audioDeviceManager.registerReceiver()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "getConnectedDevices") {
            // 매니저에 기기 목록 조회를 위임하고 결과를 반환
            val devices = audioDeviceManager.getConnectedDevices()
            result.success(devices)
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        audioDeviceManager.unregisterReceiver()
    }
}