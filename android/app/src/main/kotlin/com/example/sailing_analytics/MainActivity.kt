package com.example.sailing_analytics

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.sailing_analytics/volume_buttons"
    private var channel: MethodChannel? = null

    // Die Tasten werden nur geschluckt, solange die Racing-View läuft —
    // sonst ließe sich im Rest der App die Lautstärke nicht mehr verstellen.
    private var intercepting = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "setIntercepting" -> {
                        intercepting = call.arguments as? Boolean ?: false
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        val key = keyName(keyCode)
        if (!intercepting || key == null) return super.onKeyDown(keyCode, event)

        // Nur der erste Down startet die Geste. Androids Auto-Repeat kommt mit
        // repeatCount > 0 und würde die Haltedauer sonst laufend zurücksetzen.
        if (event?.repeatCount == 0) {
            channel?.invokeMethod("volumeKeyDown", key)
        }
        return true
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        val key = keyName(keyCode)
        if (!intercepting || key == null) return super.onKeyUp(keyCode, event)

        channel?.invokeMethod("volumeKeyUp", key)
        return true
    }

    private fun keyName(keyCode: Int): String? = when (keyCode) {
        KeyEvent.KEYCODE_VOLUME_UP -> "up"
        KeyEvent.KEYCODE_VOLUME_DOWN -> "down"
        else -> null
    }
}
