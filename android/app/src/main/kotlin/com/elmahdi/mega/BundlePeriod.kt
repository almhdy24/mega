package com.elmahdi.mega

import kotlin.math.ceil
import kotlin.math.max

data class BundlePeriod(
    val startMs: Long,
    val endMs: Long,
    val isExpired: Boolean
) {
    fun daysLeft(nowMs: Long): Int {
        if (isExpired || nowMs >= endMs) return 0
        val diffSec = (endMs - nowMs) / 1000.0
        if (diffSec <= 0) return 0
        return max(0, ceil(diffSec / 86400.0).toInt())
    }

    fun daysElapsed(nowMs: Long): Int {
        if (nowMs < startMs) return 1
        val diffDays = (nowMs - startMs) / 86400000L
        return max(1L, diffDays).toInt()
    }

    fun safeDailyAllowance(remainingBytes: Long, nowMs: Long): Long {
        val left = daysLeft(nowMs)
        if (left <= 0) return remainingBytes
        return max(0L, remainingBytes / left)
    }

    companion object {
        fun compute(
            startMs: Long,
            validityDays: Int,
            autoRenew: Boolean,
            nowMs: Long
        ): BundlePeriod {
            val validDays = max(1, validityDays)
            val validityMs = validDays * 86400000L

            if (startMs <= 0L) {
                return BundlePeriod(nowMs, nowMs + validityMs, false)
            }

            var periodStart = startMs
            var periodEnd = periodStart + validityMs

            if (autoRenew) {
                while (nowMs >= periodEnd) {
                    periodStart = periodEnd
                    periodEnd = periodStart + validityMs
                }
                return BundlePeriod(periodStart, periodEnd, false)
            } else {
                val expired = nowMs >= periodEnd
                return BundlePeriod(periodStart, periodEnd, expired)
            }
        }
    }
}
