package dev.elmahdi.mega

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

object NotificationHelper {
    const val CHANNEL_ALERTS = "alerts"
    const val CHANNEL_URGENT = "urgent"
    const val CHANNEL_SUMMARY = "summary"
    const val CHANNEL_LIVE = "live_speed"

    fun createChannels(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return

            // Alerts channel (DEFAULT)
            val alertsChannel = NotificationChannel(
                CHANNEL_ALERTS,
                "تنبيهات الباقة | Bundle Alerts",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "تنبيهات استهلاك باقة الإنترنت واقتراب النفاذ"
            }
            manager.createNotificationChannel(alertsChannel)

            // Urgent channel (HIGH)
            val urgentChannel = NotificationChannel(
                CHANNEL_URGENT,
                "تنبيهات عاجلة | Urgent Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "تنبيهات انتهاء الباقة بالكامل أو الاستهلاك المفاجئ"
                enableVibration(true)
            }
            manager.createNotificationChannel(urgentChannel)

            // Summary channel (LOW)
            val summaryChannel = NotificationChannel(
                CHANNEL_SUMMARY,
                "الملخص اليومي | Daily Summary",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "ملخص يومي هادئ لاستهلاك البيانات والمتبقي من الباقة"
                setShowBadge(false)
            }
            manager.createNotificationChannel(summaryChannel)

            // Live channel (LOW)
            val liveChannel = NotificationChannel(
                CHANNEL_LIVE,
                "عداد السرعة الحي | Live Speed",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "عرض عداد السرعة في شريط الحالة وإشعار مستمر"
                setShowBadge(false)
                setSound(null, null)
                enableVibration(false)
            }
            manager.createNotificationChannel(liveChannel)
        }
    }

    fun showAlert(context: Context, alert: AlertToFire) {
        createChannels(context)

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            alert.ruleId.hashCode(),
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val channelId = when (alert.channel) {
            "urgent" -> CHANNEL_URGENT
            "summary" -> CHANNEL_SUMMARY
            else -> CHANNEL_ALERTS
        }

        val priority = if (alert.isUrgent) {
            NotificationCompat.PRIORITY_HIGH
        } else {
            NotificationCompat.PRIORITY_DEFAULT
        }

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.stat_sys_warning)
            .setContentTitle(alert.title)
            .setContentText(alert.body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(alert.body))
            .setPriority(priority)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        manager?.notify(alert.ruleId.hashCode(), notification)
    }

    fun showThresholdAlert(context: Context, thresholdPct: Int, usedMb: Long, totalMb: Long) {
        val alert = AlertToFire(
            ruleId = "threshold_$thresholdPct",
            type = "bundle_percent",
            channel = if (thresholdPct >= 100) "urgent" else "alerts",
            title = if (thresholdPct >= 100) "تنبيه: تم استهلاك 100% من الباقة!" else "تنبيه: تم استهلاك $thresholdPct% من الباقة",
            body = "استهلكت $usedMb ميجابايت من أصل $totalMb ميجابايت.",
            isUrgent = thresholdPct >= 100
        )
        showAlert(context, alert)
    }
}
