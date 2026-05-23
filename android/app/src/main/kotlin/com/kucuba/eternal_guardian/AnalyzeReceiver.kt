package com.kucuba.eternal_guardian

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.RemoteInput

class AnalyzeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ScamDetectorForegroundService.ACTION_ANALYZE_INPUT) return

        val pendingResult = goAsync()
        val submittedText = RemoteInput.getResultsFromIntent(intent)
            ?.getCharSequence(ScamDetectorForegroundService.KEY_TEXT_REPLY)
            ?.toString()
            ?.trim()

        if (submittedText.isNullOrBlank()) {
            NotificationHelper.updateNotificationError(
                context,
                "Paste or type text in the notification input before analyzing."
            )
            pendingResult.finish()
            return
        }

        NotificationHelper.updateNotificationScanning(context)

        Thread {
            try {
                val backendUrl = ScamDetectorForegroundService.getBackendUrl(context)
                val result = HttpAnalysisClient.analyze(backendUrl, submittedText)
                if (result.riskScore in 1..100) {
                    NotificationHelper.updateNotificationResult(context, result)
                } else {
                    NotificationHelper.updateNotificationError(
                        context,
                        "Analysis temporarily unavailable. Try again."
                    )
                }
            } catch (_: Exception) {
                NotificationHelper.updateNotificationError(
                    context,
                    "Analysis failed. Check the backend connection and try again."
                )
            } finally {
                pendingResult.finish()
            }
        }.start()
    }
}
