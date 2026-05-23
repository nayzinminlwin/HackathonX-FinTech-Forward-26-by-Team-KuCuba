package com.kucuba.eternal_guardian

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "com.kucuba/notification_service"

    override fun getBackgroundMode(): BackgroundMode {
        return BackgroundMode.transparent
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val backendUrl = call.argument<String>("backend_url")
                    val intent = Intent(this, ScamDetectorForegroundService::class.java).apply {
                        putExtra(ScamDetectorForegroundService.EXTRA_BACKEND_URL, backendUrl)
                    }

                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    } catch (exception: SecurityException) {
                        result.error(
                            "notification_permission_required",
                            "Notification permission is required before starting Guardian Mode.",
                            exception.message
                        )
                    }
                }
                "stopService" -> {
                    stopService(Intent(this, ScamDetectorForegroundService::class.java))
                    result.success(true)
                }
                "isRunning" -> result.success(isServiceRunning())
                else -> result.notImplemented()
            }
        }
    }

    private fun isServiceRunning(): Boolean {
        val manager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        @Suppress("DEPRECATION")
        return manager.getRunningServices(Int.MAX_VALUE).any {
            it.service.className == ScamDetectorForegroundService::class.java.name
        }
    }
}
