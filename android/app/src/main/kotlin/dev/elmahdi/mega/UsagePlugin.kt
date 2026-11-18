package dev.elmahdi.mega

import android.app.AppOpsManager
import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.provider.Settings
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

class UsagePlugin(private val ctx: Context) : MethodChannel.MethodCallHandler {
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    companion object {
        const val CHANNEL_NAME = "dev.elmahdi.mega/usage"
        const val WORK_NAME = "mega_usage_alerts"

        fun registerWith(messenger: BinaryMessenger, context: Context) {
            val channel = MethodChannel(messenger, CHANNEL_NAME)
            val plugin = UsagePlugin(context.applicationContext)
            channel.setMethodCallHandler(plugin)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasUsageAccess" -> result.success(UsageQuery.hasAccess(ctx))
            "networkType" -> {
                try {
                    val cm = ctx.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
                    val net = cm?.activeNetwork
                    val caps = cm?.getNetworkCapabilities(net)
                    val type = when {
                        caps == null -> "none"
                        caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
                        caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "mobile"
                        caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
                        else -> "none"
                    }
                    result.success(type)
                } catch (t: Throwable) {
                    result.success("none")
                }
            }
            "openUsageAccessSettings" -> {
                try {
                    ctx.startActivity(
                        Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    )
                    result.success(null)
                } catch (t: Throwable) {
                    result.error("INTENT_FAILED", t.message, null)
                }
            }
            "queryRange" -> {
                val startMs = (call.argument<Number>("startMs"))?.toLong() ?: 0L
                val endMs = (call.argument<Number>("endMs"))?.toLong() ?: 0L
                io.execute {
                    try {
                        val r = UsageQuery.range(ctx, startMs, endMs)
                        main.post { result.success(r) }
                    } catch (t: Throwable) {
                        main.post { result.error("QUERY_FAILED", t.message, null) }
                    }
                }
            }
            "queryTopApps" -> {
                val startMs = (call.argument<Number>("startMs"))?.toLong() ?: 0L
                val endMs = (call.argument<Number>("endMs"))?.toLong() ?: 0L
                val limit = (call.argument<Number>("limit"))?.toInt() ?: 10
                io.execute {
                    try {
                        val list = UsageQuery.topApps(ctx, startMs, endMs, limit)
                        main.post { result.success(list) }
                    } catch (t: Throwable) {
                        main.post { result.error("QUERY_FAILED", t.message, null) }
                    }
                }
            }
            "scheduleAlertWorker" -> {
                try {
                    val workRequest = PeriodicWorkRequestBuilder<UsageWorker>(
                        15, TimeUnit.MINUTES
                    ).build()
                    WorkManager.getInstance(ctx).enqueueUniquePeriodicWork(
                        WORK_NAME,
                        ExistingPeriodicWorkPolicy.UPDATE,
                        workRequest
                    )
                    result.success(true)
                } catch (t: Throwable) {
                    result.error("WORK_FAILED", t.message, null)
                }
            }
            "cancelAlertWorker" -> {
                try {
                    WorkManager.getInstance(ctx).cancelUniqueWork(WORK_NAME)
                    result.success(true)
                } catch (t: Throwable) {
                    result.error("CANCEL_FAILED", t.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }
}

object UsageQuery {
    fun hasAccess(ctx: Context): Boolean {
        val ops = ctx.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager ?: return false
        val mode = if (Build.VERSION.SDK_INT >= 29) {
            ops.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                ctx.packageName
            )
        } else {
            @Suppress("DEPRECATION")
            ops.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                ctx.packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    fun range(ctx: Context, startMs: Long, endMs: Long): Map<String, Any> {
        val nsm = ctx.getSystemService(Context.NETWORK_STATS_SERVICE) as? NetworkStatsManager
            ?: return mapOf(
                "mobileRx" to 0L,
                "mobileTx" to 0L,
                "wifiRx" to 0L,
                "wifiTx" to 0L,
                "mobileSupported" to false
            )

        var mobileSupported = Build.VERSION.SDK_INT >= 29
        var mRx = 0L
        var mTx = 0L

        if (Build.VERSION.SDK_INT >= 29) {
            try {
                val b = nsm.querySummaryForDevice(ConnectivityManager.TYPE_MOBILE, null, startMs, endMs)
                mRx = b.rxBytes
                mTx = b.txBytes
            } catch (_: Throwable) {
                mobileSupported = false
            }
        } else {
            // Android 8.0-9.0 (API 26-28) requires READ_PHONE_STATE/subscriberId for mobile stats
            mobileSupported = false
        }

        var wRx = 0L
        var wTx = 0L
        try {
            val b = nsm.querySummaryForDevice(ConnectivityManager.TYPE_WIFI, null, startMs, endMs)
            wRx = b.rxBytes
            wTx = b.txBytes
        } catch (_: Throwable) {}

        return mapOf(
            "mobileRx" to mRx,
            "mobileTx" to mTx,
            "wifiRx" to wRx,
            "wifiTx" to wTx,
            "mobileSupported" to mobileSupported
        )
    }

    fun topApps(ctx: Context, startMs: Long, endMs: Long, limit: Int = 10): List<Map<String, Any>> {
        val nsm = ctx.getSystemService(Context.NETWORK_STATS_SERVICE) as? NetworkStatsManager ?: return emptyList()
        if (Build.VERSION.SDK_INT < 28) return emptyList()

        val uidMobile = mutableMapOf<Int, Long>()
        val uidWifi = mutableMapOf<Int, Long>()

        try {
            val stats = nsm.querySummary(ConnectivityManager.TYPE_MOBILE, null, startMs, endMs)
            val bucket = NetworkStats.Bucket()
            while (stats.hasNextBucket()) {
                stats.getNextBucket(bucket)
                val uid = bucket.uid
                if (uid > 0) {
                    val bytes = bucket.rxBytes + bucket.txBytes
                    uidMobile[uid] = (uidMobile[uid] ?: 0L) + bytes
                }
            }
            stats.close()
        } catch (_: Throwable) {}

        try {
            val stats = nsm.querySummary(ConnectivityManager.TYPE_WIFI, null, startMs, endMs)
            val bucket = NetworkStats.Bucket()
            while (stats.hasNextBucket()) {
                stats.getNextBucket(bucket)
                val uid = bucket.uid
                if (uid > 0) {
                    val bytes = bucket.rxBytes + bucket.txBytes
                    uidWifi[uid] = (uidWifi[uid] ?: 0L) + bytes
                }
            }
            stats.close()
        } catch (_: Throwable) {}

        val allUids = (uidMobile.keys + uidWifi.keys).toSet()
        val sortedUids = allUids.sortedByDescending { (uidMobile[it] ?: 0L) + (uidWifi[it] ?: 0L) }.take(limit)

        val pm = ctx.packageManager
        return sortedUids.map { uid ->
            val packages = try { pm.getPackagesForUid(uid) } catch (_: Throwable) { null }
            val pkg = packages?.firstOrNull() ?: "UID $uid"
            val label = try {
                val appInfo = pm.getApplicationInfo(pkg, 0)
                pm.getApplicationLabel(appInfo).toString()
            } catch (_: Throwable) {
                pkg
            }
            mapOf(
                "uid" to uid,
                "packageName" to pkg,
                "appName" to label,
                "mobileBytes" to (uidMobile[uid] ?: 0L),
                "wifiBytes" to (uidWifi[uid] ?: 0L)
            )
        }
    }
    }
}
