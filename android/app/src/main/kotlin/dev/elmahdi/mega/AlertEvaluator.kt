package dev.elmahdi.mega

data class AlertRule(
    val id: String,
    val type: String, // "bundle_percent", "bundle_remaining", "daily_limit", "pace_warning", "expiry_reminder", "usage_spike", "bundle_exhausted", "daily_summary"
    val enabled: Boolean = true,
    val threshold: Long = 0L, // percentage (e.g. 50, 80) or bytes (e.g. 500*1024*1024) or hours (e.g. 24)
    val channel: String = "alerts", // "alerts", "urgent", "summary"
    val target: String = "mobile" // "mobile", "all"
)

data class AlertState(
    val bundleId: Long = 0L,
    val firedRuleIds: Set<String> = emptySet(),
    val lastExhaustedRemindMs: Long = 0L
)

data class UsageSnapshotData(
    val todayMobileBytes: Long = 0L,
    val periodMobileBytes: Long = 0L,
    val lastHourBytes: Long = 0L,
    val sevenDayAvgDailyBytes: Long = 0L
)

data class BundleEvalInfo(
    val id: Long,
    val totalBytes: Long,
    val startMs: Long,
    val endMs: Long,
    val validityDays: Int
)

data class AlertToFire(
    val ruleId: String,
    val type: String,
    val channel: String,
    val title: String,
    val body: String,
    val isUrgent: Boolean = false
)

object AlertEvaluator {

    fun isQuietHour(hour: Int, startHour: Int, endHour: Int): Boolean {
        if (startHour == endHour) return false
        return if (startHour < endHour) {
            hour in startHour until endHour
        } else {
            hour >= startHour || hour < endHour
        }
    }

    fun evaluate(
        snapshot: UsageSnapshotData,
        bundle: BundleEvalInfo?,
        rules: List<AlertRule>,
        nowMs: Long,
        state: AlertState,
        currentHour: Int = -1,
        quietStartHour: Int = -1,
        quietEndHour: Int = -1
    ): Pair<List<AlertToFire>, AlertState> {
        // If bundle changed (renewed or new id), clear fired rules
        val effectiveState = if (bundle != null && bundle.id != state.bundleId) {
            AlertState(bundleId = bundle.id, firedRuleIds = emptySet())
        } else {
            state
        }

        val inQuiet = if (currentHour >= 0 && quietStartHour >= 0 && quietEndHour >= 0) {
            isQuietHour(currentHour, quietStartHour, quietEndHour)
        } else {
            false
        }

        val toFire = mutableListOf<AlertToFire>()
        val newlyFired = effectiveState.firedRuleIds.toMutableSet()
        var updatedExhaustedMs = effectiveState.lastExhaustedRemindMs

        for (rule in rules) {
            if (!rule.enabled) continue

            when (rule.type) {
                "bundle_percent" -> {
                    if (bundle != null && bundle.totalBytes > 0) {
                        val pct = ((snapshot.periodMobileBytes * 100.0) / bundle.totalBytes).toInt()
                        if (pct >= rule.threshold && !newlyFired.contains(rule.id)) {
                            toFire.add(
                                AlertToFire(
                                    ruleId = rule.id,
                                    type = rule.type,
                                    channel = if (rule.threshold >= 100) "urgent" else rule.channel,
                                    title = "تنبيه الباقة: تم استهلاك ${rule.threshold}%",
                                    body = "وصل استهلاكك إلى ${rule.threshold}% من سعة باقتك المحددة.",
                                    isUrgent = rule.threshold >= 100
                                )
                            )
                            newlyFired.add(rule.id)
                        }
                    }
                }
                "bundle_remaining" -> {
                    if (bundle != null && bundle.totalBytes > 0) {
                        val rem = bundle.totalBytes - snapshot.periodMobileBytes
                        if (rem <= rule.threshold && rem >= 0 && !newlyFired.contains(rule.id)) {
                            val remMb = (rem / (1024 * 1024)).coerceAtLeast(0)
                            toFire.add(
                                AlertToFire(
                                    ruleId = rule.id,
                                    type = rule.type,
                                    channel = rule.channel,
                                    title = "تنبيه الباقة: اقتراب النفاذ",
                                    body = "تبقى في باقتك حوالي $remMb ميجابايت فقط.",
                                    isUrgent = false
                                )
                            )
                            newlyFired.add(rule.id)
                        }
                    }
                }
                "daily_limit" -> {
                    if (snapshot.todayMobileBytes >= rule.threshold && !newlyFired.contains(rule.id)) {
                        val limitMb = rule.threshold / (1024 * 1024)
                        toFire.add(
                            AlertToFire(
                                ruleId = rule.id,
                                type = rule.type,
                                channel = rule.channel,
                                title = "تنبيه الحد اليومي",
                                body = "تجاوز استهلاكك لبيانات الهاتف اليوم $limitMb ميجابايت.",
                                isUrgent = false
                            )
                        )
                        newlyFired.add(rule.id)
                    }
                }
                "pace_warning" -> {
                    if (bundle != null && bundle.totalBytes > 0 && nowMs > bundle.startMs) {
                        val elapsedDays = ((nowMs - bundle.startMs) / (24 * 3600 * 1000.0)).coerceAtLeast(0.5)
                        val remainingDays = ((bundle.endMs - nowMs) / (24 * 3600 * 1000.0)).coerceAtLeast(0.1)
                        val remainingBytes = bundle.totalBytes - snapshot.periodMobileBytes

                        if (remainingBytes > 0) {
                            val dailyRate = snapshot.periodMobileBytes / elapsedDays
                            val daysUntilOut = remainingBytes / dailyRate
                            if (daysUntilOut < remainingDays && !newlyFired.contains(rule.id)) {
                                toFire.add(
                                    AlertToFire(
                                        ruleId = rule.id,
                                        type = rule.type,
                                        channel = rule.channel,
                                        title = "تحذير وتيرة الاستهلاك",
                                        body = "بمعدل استهلاكك الحالي، ستنفذ الباقة قبل موعد تجديدها.",
                                        isUrgent = false
                                    )
                                )
                                newlyFired.add(rule.id)
                            }
                        }
                    }
                }
                "expiry_reminder" -> {
                    if (bundle != null && nowMs < bundle.endMs) {
                        val hoursLeft = ((bundle.endMs - nowMs) / (3600 * 1000)).toInt()
                        if (hoursLeft in 1..rule.threshold.toInt() && !newlyFired.contains(rule.id)) {
                            toFire.add(
                                AlertToFire(
                                    ruleId = rule.id,
                                    type = rule.type,
                                    channel = rule.channel,
                                    title = "تذكير انتهاء صلاحية الباقة",
                                    body = "تبقى $hoursLeft ساعة فقط على انتهاء صلاحية باقتك الحالية.",
                                    isUrgent = false
                                )
                            )
                            newlyFired.add(rule.id)
                        }
                    }
                }
                "usage_spike" -> {
                    if (rule.threshold > 0 && snapshot.lastHourBytes >= rule.threshold && !newlyFired.contains(rule.id)) {
                        val mb = snapshot.lastHourBytes / (1024 * 1024)
                        toFire.add(
                            AlertToFire(
                                ruleId = rule.id,
                                type = rule.type,
                                channel = rule.channel,
                                title = "تنبيه استهلاك مفاجئ",
                                body = "تم استهلاك $mb ميجابايت خلال الساعة الأخيرة.",
                                isUrgent = false
                            )
                        )
                        newlyFired.add(rule.id)
                    }
                }
                "bundle_exhausted" -> {
                    if (bundle != null && bundle.totalBytes > 0 && snapshot.periodMobileBytes >= bundle.totalBytes) {
                        val remindInterval = 6 * 3600 * 1000L // 6 hours
                        val canFire = !newlyFired.contains(rule.id) || (nowMs - updatedExhaustedMs >= remindInterval)
                        if (canFire) {
                            toFire.add(
                                AlertToFire(
                                    ruleId = rule.id,
                                    type = rule.type,
                                    channel = "urgent",
                                    title = "انتهت الباقة بالكامل (100%)",
                                    body = "لقد استنفدت كامل رصيد باقة الإنترنت المحددة.",
                                    isUrgent = true
                                )
                            )
                            newlyFired.add(rule.id)
                            updatedExhaustedMs = nowMs
                        }
                    }
                }
            }
        }

        // Apply quiet hours filter: suppress non-urgent alerts during quiet hours
        val finalAlerts = if (inQuiet) {
            toFire.filter { it.isUrgent }
        } else {
            toFire
        }

        return Pair(
            finalAlerts,
            effectiveState.copy(
                bundleId = bundle?.id ?: effectiveState.bundleId,
                firedRuleIds = newlyFired,
                lastExhaustedRemindMs = updatedExhaustedMs
            )
        )
    }
}
