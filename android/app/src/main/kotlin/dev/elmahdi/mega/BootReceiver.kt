package dev.elmahdi.mega

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != Intent.ACTION_BOOT_COMPLETED) return

        val prefs = Prefs.get(context)
        val monitorEnabled = prefs.getBoolean(Prefs.KEY_LIVE_MONITOR_ENABLED, false)
        val startOnBoot = prefs.getBoolean(Prefs.KEY_LIVE_MONITOR_START_BOOT, true)

        if (monitorEnabled && startOnBoot) {
            LiveMonitorService.start(context)
        }

        val alertsEnabled = prefs.getBoolean(Prefs.KEY_ALERTS_ENABLED, true)
        val bundleBytes = Prefs.getLong(prefs, Prefs.KEY_BUNDLE_BYTES, 0L)
        if (alertsEnabled && bundleBytes > 0) {
            val workRequest = PeriodicWorkRequestBuilder<UsageWorker>(
                15, TimeUnit.MINUTES
            ).build()
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                UsagePlugin.WORK_NAME,
                ExistingPeriodicWorkPolicy.UPDATE,
                workRequest
            )
        }
    }
}
