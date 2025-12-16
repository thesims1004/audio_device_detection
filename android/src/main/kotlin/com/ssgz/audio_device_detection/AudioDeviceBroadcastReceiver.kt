package com.ssgz.audio_device_detection

import android.bluetooth.BluetoothA2dp
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothHeadset
import android.bluetooth.BluetoothProfile
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioManager

class AudioDeviceBroadcastReceiver(
    private val onStateChanged: (Map<String, Any?>) -> Unit
) : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action

        // 1. 블루투스 관련 로직 (기존 코드 유지하되 결과 처리를 onStateChanged로 통일)
        if (action == BluetoothA2dp.ACTION_CONNECTION_STATE_CHANGED ||
            action == BluetoothHeadset.ACTION_CONNECTION_STATE_CHANGED) {

            val device: BluetoothDevice? = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
            val state = intent.getIntExtra(BluetoothProfile.EXTRA_STATE, -1)

            if (device != null) {
                val profile = if (action == BluetoothA2dp.ACTION_CONNECTION_STATE_CHANGED)
                    BluetoothProfile.A2DP else BluetoothProfile.HEADSET

                val isConnected = state == BluetoothProfile.STATE_CONNECTED
                // 연결 중/해제 중 상태는 무시하고 확실한 상태만 보낼 경우:
                if (state == BluetoothProfile.STATE_CONNECTED || state == BluetoothProfile.STATE_DISCONNECTED) {
                    val map = AudioDeviceMapper.fromBluetoothDevice(device, profile, isConnected)
                    onStateChanged(map)
                }
            }
        }

        // 2. [NEW] 유선 헤드셋 로직 추가
        else if (action == AudioManager.ACTION_HEADSET_PLUG) {
            val state = intent.getIntExtra("state", -1)
            val name = intent.getStringExtra("name") ?: "Wired Headset"
            val microphone = intent.getIntExtra("microphone", 0)

            // state: 0 = unplugged, 1 = plugged
            val isConnected = state == 1
            val protocol = if (microphone == 1) "wired_headset" else "wired_headphones"

            val map = AudioDeviceMapper.createDeviceMap(
                name = "Wired Headset",
                address = "wired_device",
                protocol = protocol,
                isConnected = isConnected
            )
            onStateChanged(map)
        }
    }
}