package com.elmahdi.mega

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class BundlePeriodTest {

    @Test
    fun testFreshBundleWithinPeriod() {
        val startMs = 1770000000000L
        val nowMs = startMs + (4 * 86400000L) // 4 days later
        val period = BundlePeriod.compute(
            startMs = startMs,
            validityDays = 30,
            autoRenew = false,
            nowMs = nowMs
        )

        assertEquals(startMs, period.startMs)
        assertEquals(startMs + (30 * 86400000L), period.endMs)
        assertFalse(period.isExpired)
        assertEquals(26, period.daysLeft(nowMs))
        assertEquals(4, period.daysElapsed(nowMs))
    }

    @Test
    fun testExpiredBundleWithoutAutoRenew() {
        val startMs = 1770000000000L
        val nowMs = startMs + (35 * 86400000L) // 35 days later
        val period = BundlePeriod.compute(
            startMs = startMs,
            validityDays = 30,
            autoRenew = false,
            nowMs = nowMs
        )

        assertTrue(period.isExpired)
        assertEquals(0, period.daysLeft(nowMs))
    }

    @Test
    fun testExpiredBundleWithAutoRenew() {
        val startMs = 1770000000000L
        val validityMs = 30 * 86400000L
        val nowMs = startMs + (35 * 86400000L) // 35 days later (in cycle 2)

        val period = BundlePeriod.compute(
            startMs = startMs,
            validityDays = 30,
            autoRenew = true,
            nowMs = nowMs
        )

        assertFalse(period.isExpired)
        assertEquals(startMs + validityMs, period.startMs)
        assertEquals(startMs + (2 * validityMs), period.endMs)
        assertEquals(25, period.daysLeft(nowMs))
    }

    @Test
    fun testSafeDailyAllowance() {
        val startMs = 1770000000000L
        val nowMs = startMs + (20 * 86400000L) // 10 days left
        val period = BundlePeriod.compute(
            startMs = startMs,
            validityDays = 30,
            autoRenew = false,
            nowMs = nowMs
        )

        val remainingBytes = 10_000_000_000L // 10 GB
        val allowance = period.safeDailyAllowance(remainingBytes, nowMs)
        assertEquals(1_000_000_000L, allowance) // 1 GB / day
    }
}
