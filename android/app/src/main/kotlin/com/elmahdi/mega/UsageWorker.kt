package com.elmahdi.mega

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

class UsageWorker(
    appContext: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(appContext, workerParams) {

    override suspend fun doWork(): Result {
        val ctx = applicationContext

        // 1. Check usage access
        if (!UsageQuery.hasAccess(ctx)) {
            return Result.success()
        }

        // 2. Read preferences
        val prefs = Prefs.get(ctx)
        val alertsEnabled = prefs.getBoolean(Prefs.KEY_ALERTS_ENABLED, true)
        if (!alertsEnabled) {
            return Result.success()
        }

        val bundleBytes = Prefs.getLong(prefs, Prefs.KEY_BUNDLE_BYTES, 0L)
        val bundleStartMs = Prefs.getLong(prefs, Prefs.KEY_BUNDLE_START_MS, 0L)
        val validityDays = Prefs.getInt(prefs, Prefs.KEY_BUNDLE_VALIDITY_DAYS, 30)
        val autoRenew = prefs.getBoolean(Prefs.KEY_BUNDLE_AUTO_RENEW, true)
        val bundleId = Prefs.getLong(prefs, Prefs.KEY_BUNDLE_ID, 1L)

        val now = Calendar.getInstance()
        val nowMs = now.timeInMillis
        val currentHour = now.get(Calendar.HOUR_OF_DAY)

        // 3. Compute bundle period
        val bundleInfo = if (bundleBytes > 0 && bundleStartMs > 0) {
            val period = BundlePeriod.compute(bundleStartMs, validityDays, autoRenew, nowMs)
            BundleEvalInfo(
                id = bundleId,
                totalBytes = bundleBytes,
                startMs = period.startMs,
                endMs = period.endMs,
                validityDays = validityDays
            )
        } else {
            null
        }

        // 4. Query usage
        val startOfDay = Calendar.getInstance().apply {
            timeInMillis = nowMs
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis

        val dailyRange = UsageQuery.range(ctx, startOfDay, nowMs)
        val todayMobile = ((dailyRange["mobileRx"] as? Number)?.toLong() ?: 0L) +
                ((dailyRange["mobileTx"] as? Number)?.toLong() ?: 0L)

        val periodMobile = if (bundleInfo != null) {
            val periodRange = UsageQuery.range(ctx, bundleInfo.startMs, nowMs)
            ((periodRange["mobileRx"] as? Number)?.toLong() ?: 0L) +
                    ((periodRange["mobileTx"] as? Number)?.toLong() ?: 0L)
        } else {
            0L
        }

        // Last hour usage
        val oneHourAgo = nowMs - (3600 * 1000L)
        val lastHourRange = UsageQuery.range(ctx, oneHourAgo, nowMs)
        val lastHourMobile = ((lastHourRange["mobileRx"] as? Number)?.toLong() ?: 0L) +
                ((lastHourRange["mobileTx"] as? Number)?.toLong() ?: 0L)

        val snapshot = UsageSnapshotData(
            todayMobileBytes = todayMobile,
            periodMobileBytes = periodMobile,
            lastHourBytes = lastHourMobile
        )

        // 5. Parse rules
        val rules = parseAlertRules(prefs.getString(Prefs.KEY_ALERT_RULES, null))

        // 6. Read saved fired state
        val savedFiredState = parseAlertState(prefs)

        // 7. Evaluate
        val (alertsToFire, newState) = AlertEvaluator.evaluate(
            snapshot = snapshot,
            bundle = bundleInfo,
            rules = rules,
            nowMs = nowMs,
            state = savedFiredState,
            currentHour = currentHour,
            quietStartHour = 22,
            quietEndHour = 7
        )

        // 8. Fire notifications
        for (alert in alertsToFire) {
            NotificationHelper.showAlert(ctx, alert)
        }

        // 9. Persist updated fired state
        saveAlertState(prefs, newState)

        return Result.success()
    }

    private fun parseAlertRules(raw: String?): List<AlertRule> {
        if (raw.isNullOrEmpty()) {
            return listOf(
                AlertRule(id = "pct_50", type = "bundle_percent", threshold = 50),
                AlertRule(id = "pct_80", type = "bundle_percent", threshold = 80),
                AlertRule(id = "pct_100", type = "bundle_percent", threshold = 100, channel = "urgent"),
                AlertRule(id = "rem_500mb", type = "bundle_remaining", threshold = 500L * 1024L * 1024L),
                AlertRule(id = "pace", type = "pace_warning"),
                AlertRule(id = "exp_24h", type = "expiry_reminder", threshold = 24),
                AlertRule(id = "exhausted", type = "bundle_exhausted", channel = "urgent")
            )
        }
        return try {
            val list = mutableListOf<AlertRule>()
            val arr = JSONArray(raw)
            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                list.add(
                    AlertRule(
                        id = obj.optString("id", "rule_$i"),
                        type = obj.optString("type", "bundle_percent"),
                        enabled = obj.optBoolean("enabled", true),
                        threshold = obj.optLong("threshold", 0L),
                        channel = obj.optString("channel", "alerts"),
                        target = obj.optString("target", "mobile")
                    )
                )
            }
            list
        } catch (_: Exception) {
            listOf(
                AlertRule(id = "pct_50", type = "bundle_percent", threshold = 50),
                AlertRule(id = "pct_80", type = "bundle_percent", threshold = 80),
                AlertRule(id = "pct_100", type = "bundle_percent", threshold = 100, channel = "urgent")
            )
        }
    }

    private fun parseAlertState(prefs: android.content.SharedPreferences): AlertState {
        val bundleId = Prefs.getLong(prefs, "flutter.notified_bundle_id", 0L)
        val rawFired = prefs.getString("flutter.notified_fired_rule_ids", "[]") ?: "[]"
        val firedSet = mutableSetOf<String>()
        try {
            val arr = JSONArray(rawFired)
            for (i in 0 until arr.length()) {
                firedSet.add(arr.getString(i))
            }
        } catch (_: Exception) {}

        val lastExh = Prefs.getLong(prefs, "flutter.last_exhausted_remind_ms", 0L)
        return AlertState(
            bundleId = bundleId,
            firedRuleIds = firedSet,
            lastExhaustedRemindMs = lastExh
        )
    }

    private fun saveAlertState(prefs: android.content.SharedPreferences, state: AlertState) {
        val arr = JSONArray()
        state.firedRuleIds.forEach { arr.put(it) }
        prefs.edit()
            .putLong("flutter.notified_bundle_id", state.bundleId)
            .putString("flutter.notified_fired_rule_ids", arr.toString())
            .putLong("flutter.last_exhausted_remind_ms", state.lastExhaustedRemindMs)
            .apply()
    }
}
