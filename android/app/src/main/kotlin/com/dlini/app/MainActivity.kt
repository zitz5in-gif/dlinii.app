package com.dlinii.app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val deepLinkChannelName = "com.dlinii.app/deeplink"
    private val carHudChannelName = "com.dlinii.app/car_hud"
    private var initialLink: String? = null
    private var deepLinkChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        normalizeSharedLocation(intent)
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        normalizeSharedLocation(intent)
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun normalizeSharedLocation(intent: Intent?) {
        if (intent?.action == Intent.ACTION_SEND && intent.type == "text/plain") {
            val shared = intent.getStringExtra(Intent.EXTRA_TEXT)?.trim()
            if (!shared.isNullOrEmpty()) {
                val link = Regex("""(?:https?://|geo:|dlinii://)[^\s]+""").find(shared)?.value ?: shared
                intent.data = Uri.parse(link)
                intent.action = Intent.ACTION_VIEW
            }
        }
    }
    private fun handleIntent(intent: Intent?) {
        val data = intent?.data?.toString()
        if (!data.isNullOrEmpty()) {
            initialLink = data
            deepLinkChannel?.invokeMethod("onDeepLink", data)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        deepLinkChannel = MethodChannel(messenger, deepLinkChannelName)
        deepLinkChannel?.setMethodCallHandler { call, result ->
            if (call.method == "getInitialLink") {
                result.success(initialLink)
                initialLink = null
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(messenger, carHudChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateHud" -> {
                    DliniiCarHudStore.update(call.arguments as? Map<String, Any?>)
                    result.success(null)
                }
                "clearHud" -> {
                    DliniiCarHudStore.clear()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
