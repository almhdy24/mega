package dev.elmahdi.mega

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AlertEvaluatorTest {

    private val gb = 1024L * 1024L * 1024L
    private val mb = 1024L * 1024L

    @Test
    fun testBundlePercentThresholdsCrossed() {
        val rules = listOf(
            AlertRule(id = "p50", type = "bundle_percent", threshold = 50),
            AlertRule(id = "p80", type = "bundle_percent", threshold = 80),
            AlertRule(id = "p100", type = "bundle_percent", threshold = 100)
        )
        val bundle = BundleEvalInfo(
            id = 1L,
            totalBytes = 10 * gb,
            startMs = 1_000_000L,
            endMs = 2_000_000L,
            validityDays = 30
        )
        val snapshot = UsageSnapshotData(periodMobileBytes = 6 * gb) // 60%
        val state = AlertState(bundleId = 1L)

        val (alerts, newState) = AlertEvaluator.evaluate(snapshot, bundle, rules, 1_500_000L, state)

        assertEquals(1, alerts.size)
        assertEquals("p50", alerts[0].ruleId)
        assertTrue(newState.firedRuleIds.contains("p50"))
        assertFalse(newState.firedRuleIds.contains("p80"))
    }

    @Test
    fun testNoDuplicateFiringInSameBundle() {
        val rules = listOf(
            AlertRule(id = "p50", type = "bundle_percent", threshold = 50)
        )
        val bundle = BundleEvalInfo(
            id = 1L,
            totalBytes = 10 * gb,
            startMs = 1_000_000L,
            endMs = 2_000_000L,
            validityDays = 30
        )
        val snapshot = UsageSnapshotData(periodMobileBytes = 6 * gb)
        val initialState = AlertState(bundleId = 1L, firedRuleIds = setOf("p50"))

        val (alerts, _) = AlertEvaluator.evaluate(snapshot, bundle, rules, 1_500_000L, initialState)

        assertTrue(alerts.isEmpty())
    }

    @Test
    fun testStateResetOnBundleRenewal() {
        val rules = listOf(
            AlertRule(id = "p50", type = "bundle_percent", threshold = 50)
        )
        // Old bundle was id 1, new bundle is id 2
        val newBundle = BundleEvalInfo(
            id = 2L,
            totalBytes = 10 * gb,
            startMs = 2_000_000L,
            endMs = 3_000_000L,
            validityDays = 30
        )
        val snapshot = UsageSnapshotData(periodMobileBytes = 5 * gb) // 50%
        val oldState = AlertState(bundleId = 1L, firedRuleIds = setOf("p50"))

        val (alerts, newState) = AlertEvaluator.evaluate(snapshot, newBundle, rules, 2_500_000L, oldState)

        assertEquals(1, alerts.size)
        assertEquals("p50", alerts[0].ruleId)
        assertEquals(2L, newState.bundleId)
    }

    @Test
    fun testDailyLimitCrossing() {
        val rules = listOf(
            AlertRule(id = "dl_1gb", type = "daily_limit", threshold = 1 * gb)
        )
        val snapshot = UsageSnapshotData(todayMobileBytes = 1200 * mb) // 1.2 GB
        val state = AlertState()

        val (alerts, newState) = AlertEvaluator.evaluate(snapshot, null, rules, 1_000_000L, state)

        assertEquals(1, alerts.size)
        assertEquals("dl_1gb", alerts[0].ruleId)
        assertTrue(newState.firedRuleIds.contains("dl_1gb"))
    }

    @Test
    fun testPaceWarning() {
        val dayMs = 24 * 3600 * 1000L
        val start = 1_000_000L
        val now = start + 5 * dayMs // 5 days in
        val end = start + 30 * dayMs // 25 days remaining
        val bundle = BundleEvalInfo(
            id = 1L,
            totalBytes = 10 * gb,
            startMs = start,
            endMs = end,
            validityDays = 30
        )
        // 5 days elapsed, used 5 GB (1 GB/day). Remaining: 5 GB -> at 1 GB/day will last only 5 days, but 25 days left!
        val snapshot = UsageSnapshotData(periodMobileBytes = 5 * gb)
        val rules = listOf(AlertRule(id = "pace", type = "pace_warning"))

        val (alerts, newState) = AlertEvaluator.evaluate(snapshot, bundle, rules, now, AlertState())

        assertEquals(1, alerts.size)
        assertEquals("pace", alerts[0].ruleId)
        assertTrue(newState.firedRuleIds.contains("pace"))
    }

    @Test
    fun testExpiryReminder() {
        val hourMs = 3600 * 1000L
        val end = 10_000_000L
        val now = end - 12 * hourMs // 12 hours left
        val bundle = BundleEvalInfo(
            id = 1L,
            totalBytes = 10 * gb,
            startMs = 1_000_000L,
            endMs = end,
            validityDays = 30
        )
        val rules = listOf(AlertRule(id = "exp24", type = "expiry_reminder", threshold = 24))

        val (alerts, newState) = AlertEvaluator.evaluate(UsageSnapshotData(), bundle, rules, now, AlertState())

        assertEquals(1, alerts.size)
        assertEquals("exp24", alerts[0].ruleId)
        assertTrue(newState.firedRuleIds.contains("exp24"))
    }

    @Test
    fun testUsageSpikeAlert() {
        val rules = listOf(AlertRule(id = "spike500", type = "usage_spike", threshold = 500 * mb))
        val snapshot = UsageSnapshotData(lastHourBytes = 600 * mb)

        val (alerts, newState) = AlertEvaluator.evaluate(snapshot, null, rules, 1_000_000L, AlertState())

        assertEquals(1, alerts.size)
        assertEquals("spike500", alerts[0].ruleId)
        assertTrue(newState.firedRuleIds.contains("spike500"))
    }

    @Test
    fun testQuietHoursSuppressesNonUrgentAlerts() {
        val rules = listOf(
            AlertRule(id = "p50", type = "bundle_percent", threshold = 50),
            AlertRule(id = "p100", type = "bundle_percent", threshold = 100)
        )
        val bundle = BundleEvalInfo(
            id = 1L,
            totalBytes = 10 * gb,
            startMs = 1_000_000L,
            endMs = 2_000_000L,
            validityDays = 30
        )
        // 100% usage -> p50 is normal, p100 is urgent
        val snapshot = UsageSnapshotData(periodMobileBytes = 10 * gb)

        // Hour is 23 (11 PM), quiet hours are 22 to 7 -> in quiet hours!
        val (alerts, _) = AlertEvaluator.evaluate(
            snapshot,
            bundle,
            rules,
            1_500_000L,
            AlertState(),
            currentHour = 23,
            quietStartHour = 22,
            quietEndHour = 7
        )

        // Non-urgent p50 is suppressed, urgent p100 passes through!
        assertEquals(1, alerts.size)
        assertEquals("p100", alerts[0].ruleId)
        assertTrue(alerts[0].isUrgent)
    }

    @Test
    fun testBundleExhaustedRepeatsAfter6Hours() {
        val bundle = BundleEvalInfo(
            id = 1L,
            totalBytes = 10 * gb,
            startMs = 1_000_000L,
            endMs = 2_000_000L,
            validityDays = 30
        )
        val snapshot = UsageSnapshotData(periodMobileBytes = 10 * gb)
        val rules = listOf(AlertRule(id = "exh", type = "bundle_exhausted"))

        // First firing at t = 1000
        val (alerts1, state1) = AlertEvaluator.evaluate(snapshot, bundle, rules, 1_000L, AlertState())
        assertEquals(1, alerts1.size)
        assertEquals("exh", alerts1[0].ruleId)

        // 3 hours later -> should NOT repeat yet
        val (alerts2, _) = AlertEvaluator.evaluate(
            snapshot,
            bundle,
            rules,
            1_000L + 3 * 3600 * 1000L,
            state1
        )
        assertTrue(alerts2.isEmpty())

        // 7 hours later -> should repeat!
        val (alerts3, state3) = AlertEvaluator.evaluate(
            snapshot,
            bundle,
            rules,
            1_000L + 7 * 3600 * 1000L,
            state1
        )
        assertEquals(1, alerts3.size)
        assertEquals("exh", alerts3[0].ruleId)
        assertEquals(1_000L + 7 * 3600 * 1000L, state3.lastExhaustedRemindMs)
    }
}
