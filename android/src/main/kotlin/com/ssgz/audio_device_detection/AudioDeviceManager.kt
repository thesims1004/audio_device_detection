package com.ssgz.audio_device_detection

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothA2dp
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothHeadset
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.content.IntentFilter
import android.media.AudioManager
import android.media.AudioDeviceInfo
import androidx.core.content.getSystemService
import kotlin.collections.none

class AudioDeviceManager(
    private val context: Context,
    private val onDeviceStateChanged: (Map<String, Any?>) -> Unit
) {
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private var broadcastReceiver: AudioDeviceBroadcastReceiver? = null

    // API 23 이상에서 기기 목록 가져오기 (권장)
    fun getConnectedDevices(): List<Map<String, Any?>> {
        val deviceList = mutableListOf<Map<String, Any?>>()

//        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
        val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)

        for (deviceInfo in devices) {
            val type = deviceInfo.type
            val protocolString = when (type) {
                AudioDeviceInfo.TYPE_WIRED_HEADSET,
                AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
                AudioDeviceInfo.TYPE_USB_HEADSET,
                AudioDeviceInfo.TYPE_USB_DEVICE -> "wired"

                AudioDeviceInfo.TYPE_BUILTIN_SPEAKER -> "speaker"
                AudioDeviceInfo.TYPE_BUILTIN_EARPIECE -> "earpiece"

                AudioDeviceInfo.TYPE_BLUETOOTH_A2DP -> "bluetooth_a2dp"
                AudioDeviceInfo.TYPE_BLUETOOTH_SCO -> "bluetooth_hfp"

                AudioDeviceInfo.TYPE_IP,
                AudioDeviceInfo.TYPE_BUS -> "wifi"

                else -> "unknown" // 처리되지 않은 나머지
            }

            // unknown이 아닌 경우에만 리스트에 추가
            if (protocolString != "unknown") {
                // ... 맵 생성 및 리스트 추가 로직 ...
                val map = AudioDeviceMapper.createDeviceMap(
                    deviceInfo.productName.toString(),
                    deviceInfo.address, // WiFi 기기는 IP 주소나 ID가 들어올 수 있음
                    protocolString,
                    true
                )
                deviceList.add(map)
            }
        }
//        } else {
//            // API 23 미만 (Legacy) - 필요한 경우 기존 BluetoothAdapter 로직 + 아래 로직 사용
//            // 1. 유선 확인
//            if (audioManager.isWiredHeadsetOn) {
//                deviceList.add(AudioDeviceMapper.createDeviceMap("Wired Headset", "wired_device", "wired", true))
//            }
//            // 2. 스피커는 항상 있다고 가정
//            deviceList.add(AudioDeviceMapper.createDeviceMap("Built-in Speaker", "speaker", "speaker", true))
//
//            // 3. 기존 블루투스 로직 병합 (생략)
//        }

        return deviceList
    }

    fun registerReceiver() {
        if (broadcastReceiver == null) {
            broadcastReceiver = AudioDeviceBroadcastReceiver { deviceMap ->
                onDeviceStateChanged(deviceMap)
            }

            val intentFilter = IntentFilter().apply {
                // Bluetooth
                addAction(BluetoothA2dp.ACTION_CONNECTION_STATE_CHANGED)
                addAction(BluetoothHeadset.ACTION_CONNECTION_STATE_CHANGED)
                // Wired Headset
                addAction(AudioManager.ACTION_HEADSET_PLUG)
            }
            context.registerReceiver(broadcastReceiver, intentFilter)
        }
    }

    fun unregisterReceiver() {
        broadcastReceiver?.let {
            context.unregisterReceiver(it)
            broadcastReceiver = null
        }
    }
}