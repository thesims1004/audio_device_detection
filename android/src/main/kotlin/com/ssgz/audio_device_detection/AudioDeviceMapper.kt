package com.ssgz.audio_device_detection

import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothProfile

object AudioDeviceMapper {
    // isConnected 파라미터를 추가하여 연결/해제 상태를 맵에 포함시킴
    fun fromBluetoothDevice(device: android.bluetooth.BluetoothDevice, profile: Int, isConnected: Boolean): Map<String, Any?> {
        val protocol = when (profile) {
            android.bluetooth.BluetoothProfile.A2DP -> "bluetooth_a2dp"
            android.bluetooth.BluetoothProfile.HEADSET -> "bluetooth_hfp" // HFP/HSP
            else -> "unknown"
        }
        return createDeviceMap(device.name ?: "Unknown Bluetooth", device.address, protocol, isConnected)
    }

    // [NEW] 유선 헤드셋 및 스피커용 메서드
    fun createDeviceMap(name: String, address: String, protocol: String, isConnected: Boolean): Map<String, Any?> {
        // [수정] 들어온 protocol 값을 표준화된 값으로 변환
        val unifiedProtocol = when (protocol) {
            // 안드로이드의 구체적인 유선 타입들을 "wired"로 통일
            "wired_headset", "wired_headphones", "usb_headset" -> "wired"
            else -> protocol
        }
        return mapOf(
            "name" to name,
            "address" to address, // 유선/스피커는 고유 ID가 없으므로 고정된 문자열 사용
            "protocol" to unifiedProtocol, // 통일된 프로토콜 사용
            "isConnected" to isConnected
        )
    }
}