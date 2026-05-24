package com.kucuba.eternal_guardian

import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.Color
import android.os.Build
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.RemoteInput

object NotificationHelper {
    fun buildIdleNotification(context: Context): Notification {
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val analyzePendingIntent = buildAnalyzePendingIntent(context)
        val remoteInput = RemoteInput.Builder(ScamDetectorForegroundService.KEY_TEXT_REPLY)
            .setLabel("Paste suspicious text")
            .build()
        val analyzeAction = NotificationCompat.Action.Builder(
            R.drawable.ic_shield,
            "Paste Text to Analyze",
            analyzePendingIntent
        )
            .addRemoteInput(remoteInput)
            .setAllowGeneratedReplies(false)
            .build()

        val remoteViews = RemoteViews(context.packageName, R.layout.notification_idle)

        return NotificationCompat.Builder(context, ScamDetectorForegroundService.CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_shield)
            .setCustomContentView(remoteViews)
            .setContentIntent(pendingIntent)
            .addAction(analyzeAction)
            .setOngoing(true)
            .setSilent(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    fun updateNotificationScanning(context: Context) {
        val remoteViews = RemoteViews(context.packageName, R.layout.notification_scanning)
        notify(
            context,
            buildStatusNotification(
                context,
                remoteViews,
                "Scanning message",
                "Checking the submitted text..."
            )
        )
    }

    fun updateNotificationError(context: Context, message: String) {
        val remoteViews = RemoteViews(context.packageName, R.layout.notification_status).apply {
            setTextViewText(R.id.notification_status_title, "Analysis unavailable")
            setTextViewText(R.id.notification_status_message, message)
        }

        notify(
            context,
            buildStatusNotification(
                context,
                remoteViews,
                "Analysis unavailable",
                message
            )
        )
    }

    fun updateNotificationResult(context: Context, result: HttpAnalysisClient.AnalysisResult) {
        val clampedScore = result.riskScore.coerceIn(0, 100)
        val zoneLabel = when {
            clampedScore <= 30 -> "Low risk"
            clampedScore <= 70 -> "Caution"
            else -> "High risk"
        }
        val barColor = when {
            clampedScore <= 30 -> Color.parseColor("#2ECC71")
            clampedScore <= 70 -> Color.parseColor("#F1C40F")
            else -> Color.parseColor("#E74C3C")
        }

        val remoteViews = RemoteViews(context.packageName, R.layout.notification_result).apply {
            setProgressBar(R.id.risk_bar, 100, clampedScore, false)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                setColorStateList(
                    R.id.risk_bar,
                    "setProgressTintList",
                    ColorStateList.valueOf(barColor)
                )
            }
            setTextViewText(R.id.risk_label, "$zoneLabel: $clampedScore/100")
            setTextViewText(
                R.id.analysis_message,
                result.analysisMessage.take(160)
            )
        }

        notify(
            context,
            buildStatusNotification(
                context,
                remoteViews,
                "$zoneLabel result",
                result.analysisMessage.take(160)
            )
        )
    }

    private fun buildStatusNotification(
        context: Context,
        remoteViews: RemoteViews,
        contentTitle: String,
        contentText: String
    ): Notification {
        return NotificationCompat.Builder(context, ScamDetectorForegroundService.CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_shield)
            .setCustomContentView(remoteViews)
            .setContentTitle(contentTitle)
            .setContentText(contentText)
            .setStyle(NotificationCompat.BigTextStyle().bigText(contentText))
            .setOngoing(true)
            .setSilent(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .addAction(buildAnalyzeAgainAction(context))
            .build()
    }

    private fun buildAnalyzeAgainAction(context: Context): NotificationCompat.Action {
        val remoteInput = RemoteInput.Builder(ScamDetectorForegroundService.KEY_TEXT_REPLY)
            .setLabel("Paste suspicious text")
            .build()

        return NotificationCompat.Action.Builder(
            R.drawable.ic_shield,
            "Analyze Again",
            buildAnalyzePendingIntent(context)
        )
            .addRemoteInput(remoteInput)
            .setAllowGeneratedReplies(false)
            .build()
    }

    private fun buildAnalyzePendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, AnalyzeReceiver::class.java).apply {
            action = ScamDetectorForegroundService.ACTION_ANALYZE_INPUT
        }

        val mutableFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_MUTABLE
        } else {
            0
        }

        return PendingIntent.getBroadcast(
            context,
            1,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or mutableFlag
        )
    }

    private fun notify(context: Context, notification: Notification) {
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.notify(ScamDetectorForegroundService.NOTIFICATION_ID, notification)
    }
}
