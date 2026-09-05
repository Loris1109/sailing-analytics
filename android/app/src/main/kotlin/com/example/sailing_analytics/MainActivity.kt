package com.example.sailing_analytics

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.sailing_analytics/volume_buttons"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                result.notImplemented()
            }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
            sendVolumeKeyEvent("up")
            return true
        } else if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            sendVolumeKeyEvent("down")
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    private fun sendVolumeKeyEvent(key: String) {
        val channel = MethodChannel(
            flutterEngine!!.dartExecutor.binaryMessenger,
            CHANNEL
        )
        channel.invokeMethod("volumeKey", key)
    }
}
