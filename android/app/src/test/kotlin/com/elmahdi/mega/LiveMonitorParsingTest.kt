package com.elmahdi.mega

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class LiveMonitorParsingTest {

    @Test
    fun testParseMobileBytesCalculatesRxPlusTx() {
        val range = mapOf(
            "mobileRx" to 1500L,
            "mobileTx" to 500L,
            "wifiRx" to 10000L,
            "wifiTx" to 5000L,
            "mobileSupported" to true
        )

        val mobile = UsageQuery.parseMobileBytes(range)
        assertEquals(2000L, mobile)

        val wifi = UsageQuery.parseWifiBytes(range)
        assertEquals(15000L, wifi)
    }

    @Test
    fun testParseMobileBytesIgnoresWifiTraffic() {
        val range = mapOf(
            "mobileRx" to 0L,
            "mobileTx" to 0L,
            "wifiRx" to 80000000L,
            "wifiTx" to 20000000L,
            "mobileSupported" to true
        )

        val mobile = UsageQuery.parseMobileBytes(range)
        assertEquals(0L, mobile)
    }

    @Test
    fun testParseMobileBytesReturnsNullWhenUnsupported() {
        val range = mapOf(
            "mobileRx" to 0L,
            "mobileTx" to 0L,
            "wifiRx" to 500L,
            "wifiTx" to 500L,
            "mobileSupported" to false
        )

        val mobile = UsageQuery.parseMobileBytes(range)
        assertNull(mobile)
    }

    @Test
    fun testBundleRemainingDecreasesOnlyWithMobileTraffic() {
        val bundleBytes = 10L * 1024L * 1024L * 1024L // 10 GB

        val periodRange = mapOf(
            "mobileRx" to 1L * 1024L * 1024L * 1024L,
            "mobileTx" to 1L * 1024L * 1024L * 1024L,
            "wifiRx" to 5L * 1024L * 1024L * 1024L,
            "wifiTx" to 5L * 1024L * 1024L * 1024L,
            "mobileSupported" to true
        )

        val periodMobile = UsageQuery.parseMobileBytes(periodRange) ?: 0L
        assertEquals(2L * 1024L * 1024L * 1024L, periodMobile)

        val remaining = (bundleBytes - periodMobile).coerceAtLeast(0L)
        // Wi-Fi 10 GB should NOT affect the 10 GB mobile bundle
        assertEquals(8L * 1024L * 1024L * 1024L, remaining)
    }
}
