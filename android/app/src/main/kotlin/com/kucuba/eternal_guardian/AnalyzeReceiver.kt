package com.kucuba.eternal_guardian

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.RemoteInput
import java.io.IOException
import java.net.ConnectException
import java.net.SocketTimeoutException
import java.net.UnknownHostException

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
                val result = if (ScamDetectorForegroundService.useMockApi(context)) {
                    MockAnalysisClient.analyze(submittedText)
                } else {
                    val backendUrl = ScamDetectorForegroundService.getBackendUrl(context)
                    HttpAnalysisClient.analyze(backendUrl, submittedText)
                }
                if (result.riskScore in 1..100) {
                    NotificationHelper.updateNotificationResult(context, result)
                } else {
                    NotificationHelper.updateNotificationError(
                        context,
                        result.analysisMessage.ifBlank {
                            "Analysis temporarily unavailable. Try again."
                        }
                    )
                }
            } catch (exception: Exception) {
                NotificationHelper.updateNotificationError(
                    context,
                    errorMessageFor(exception)
                )
            } finally {
                pendingResult.finish()
            }
        }.start()
    }

    private fun errorMessageFor(exception: Exception): String {
        return when (exception) {
            is ConnectException -> "Cannot reach backend. Start the server or set API_BASE_URL to your computer LAN IP."
            is SocketTimeoutException -> "Backend connection timed out. Check Wi-Fi and server status."
            is UnknownHostException -> "Backend host not found. Check API_BASE_URL."
            is IOException -> {
                val message = exception.message.orEmpty()
                if (message.contains("Cleartext", ignoreCase = true)) {
                    "Local HTTP is blocked. Rebuild with dev cleartext enabled."
                } else {
                    "Backend connection failed. Check server and API_BASE_URL."
                }
            }
            else -> "Analysis failed. ${exception.message ?: "Please try again."}"
        }
    }
}
