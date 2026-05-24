package com.kucuba.eternal_guardian

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder

class ScamDetectorForegroundService : Service() {
    companion object {
        const val CHANNEL_ID = "scam_detector_channel"
        const val NOTIFICATION_ID = 1001
        const val EXTRA_BACKEND_URL = "backend_url"
        const val EXTRA_USE_MOCK_API = "use_mock_api"
        const val ACTION_ANALYZE_INPUT = "com.kucuba.ACTION_ANALYZE_INPUT"
        const val KEY_TEXT_REPLY = "notification_text_input"

        private const val PREFS_NAME = "guardian_notification"
        private const val PREF_BACKEND_URL = "backend_url"
        private const val PREF_USE_MOCK_API = "use_mock_api"
        private const val DEFAULT_BACKEND_URL = "http://10.0.2.2:8080"

        fun getBackendUrl(context: android.content.Context): String {
            return context.getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
                .getString(PREF_BACKEND_URL, DEFAULT_BACKEND_URL)
                ?: DEFAULT_BACKEND_URL
        }

        fun useMockApi(context: android.content.Context): Boolean {
            return context.getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
                .getBoolean(PREF_USE_MOCK_API, true)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.getStringExtra(EXTRA_BACKEND_URL)?.takeIf { it.isNotBlank() }?.let { backendUrl ->
            getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
                .edit()
                .putString(PREF_BACKEND_URL, backendUrl)
                .apply()
        }
        if (intent?.hasExtra(EXTRA_USE_MOCK_API) == true) {
            getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
                .edit()
                .putBoolean(PREF_USE_MOCK_API, intent.getBooleanExtra(EXTRA_USE_MOCK_API, false))
                .apply()
        }

        val notification = NotificationHelper.buildIdleNotification(this)
        startForeground(NOTIFICATION_ID, notification)
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Scam Detector Guardian",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Pinned notification for user-triggered scam analysis"
            setShowBadge(false)
        }

        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }
}
