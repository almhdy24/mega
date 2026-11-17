package dev.elmahdi.mega

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import org.json.JSONArray
import java.util.Calendar

class UsageWorker(
    appContext: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(appContext, workerParams) {

    override suspend fun doWork(): Result {
        val ctx = applicationContext

        // 1. Check usage permission
        if (!UsageQuery.hasAccess(ctx)) {
            return Result.success()
        }

        // 2. Read Flutter shared preferences
        val prefs = ctx.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val alertsEnabled = prefs.getBoolean("flutter.alerts_enabled", true)
        if (!alertsEnabled) {
            return Result.success()
        }

        val bundleBytes = prefs.getLong("flutter.bundle_bytes", 0L)
        if (bundleBytes <= 0L) {
            return Result.success()
        }

        val cycleStartDay = prefs.getInt("flutter.cycle_start_day", 1)

        // 3. Compute current billing cycle start epoch
        val now = Calendar.getInstance()
        val cycleStart = getCycleStart(now, cycleStartDay)
        val cycleStartMs = cycleStart.timeInMillis
        val nowMs = now.timeInMillis

        // Check if cycle rolled over
        val savedCycleStart = prefs.getLong("flutter.notified_cycle_start", 0L)
        val notifiedSet = mutableSetOf<Int>()

        if (savedCycleStart != cycleStartMs) {
            // New cycle started: clear notified thresholds
            prefs.edit()
                .putLong("flutter.notified_cycle_start", cycleStartMs)
                .putString("flutter.notified_thresholds", "[]")
                .apply()
        } else {
            val notifiedRaw = prefs.getString("flutter.notified_thresholds", "[]") ?: "[]"
            try {
                val jsonArr = JSONArray(notifiedRaw)
                for (i in 0 until jsonArr.length()) {
                    notifiedSet.add(jsonArr.getInt(i))
                }
            } catch (_: Exception) {}
        }

        // Parse alert thresholds (default 50, 80, 100)
        val thresholds = mutableListOf(50, 80, 100)
        val thresholdsRaw = prefs.getString("flutter.alert_thresholds", null)
        if (!thresholdsRaw.isNullOrEmpty()) {
            try {
                thresholds.clear()
                val jsonArr = JSONArray(thresholdsRaw)
                for (i in 0 until jsonArr.length()) {
                    thresholds.add(jsonArr.getInt(i))
                }
            } catch (_: Exception) {
                thresholds.addAll(listOf(50, 80, 100))
            }
        }
        thresholds.sort()

        // 4. Query current mobile usage from cycle start to now
        val usageMap = UsageQuery.range(ctx, cycleStartMs, nowMs)
        val mobileRx = usageMap["mobileRx"] ?: 0L
        val mobileTx = usageMap["mobileTx"] ?: 0L
        val mobileUsedBytes = mobileRx + mobileTx

        // 5. Evaluate newly crossed thresholds
        val pct = (mobileUsedBytes.toDouble() * 100.0) / bundleBytes.toDouble()
        val newlyCrossed = thresholds.filter { t -> pct >= t && !notifiedSet.contains(t) }

        if (newlyCrossed.isNotEmpty()) {
            val usedMb = mobileUsedBytes / (1024 * 1024)
            val totalMb = bundleBytes / (1024 * 1024)

            for (t in newlyCrossed) {
                NotificationHelper.showThresholdAlert(ctx, t, usedMb, totalMb)
                notifiedSet.add(t)
            }

            // Persist updated notified thresholds
            val jsonArr = JSONArray()
            notifiedSet.sorted().forEach { jsonArr.put(it) }
            prefs.edit()
                .putString("flutter.notified_thresholds", jsonArr.toString())
                .apply()
        }

        return Result.success()
    }

    private fun getCycleStart(now: Calendar, startDay: Int): Calendar {
        fun anchor(year: Int, month: Int): Calendar {
            val cal = Calendar.getInstance().apply {
                clear()
                set(Calendar.YEAR, year)
                set(Calendar.MONTH, month)
                val maxDay = getActualMaximum(Calendar.DAY_OF_MONTH)
                set(Calendar.DAY_OF_MONTH, startDay.coerceIn(1, maxDay))
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            return cal
        }

        var start = anchor(now.get(Calendar.YEAR), now.get(Calendar.MONTH))
        if (start.after(now)) {
            val prevMonthCal = Calendar.getInstance().apply {
                timeInMillis = now.timeInMillis
                add(Calendar.MONTH, -1)
            }
            start = anchor(prevMonthCal.get(Calendar.YEAR), prevMonthCal.get(Calendar.MONTH))
        }
        return start
    }
}
