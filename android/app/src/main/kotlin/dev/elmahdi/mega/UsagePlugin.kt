package dev.elmahdi.mega

import android.app.AppOpsManager
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class UsagePlugin(private val ctx: Context) : MethodChannel.MethodCallHandler {
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    companion object {
        const val CHANNEL_NAME = "dev.elmahdi.mega/usage"

        fun registerWith(messenger: BinaryMessenger, context: Context) {
            val channel = MethodChannel(messenger, CHANNEL_NAME)
            val plugin = UsagePlugin(context.applicationContext)
            channel.setMethodCallHandler(plugin)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasUsageAccess" -> result.success(UsageQuery.hasAccess(ctx))
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

    fun range(ctx: Context, startMs: Long, endMs: Long): Map<String, Long> {
        val nsm = ctx.getSystemService(Context.NETWORK_STATS_SERVICE) as? NetworkStatsManager
            ?: return mapOf("mobileRx" to 0L, "mobileTx" to 0L, "wifiRx" to 0L, "wifiTx" to 0L)

        fun q(type: Int): Pair<Long, Long> {
            return try {
                val b = nsm.querySummaryForDevice(type, null, startMs, endMs)
                (b.rxBytes) to (b.txBytes)
            } catch (_: Throwable) {
                0L to 0L
            }
        }

        val (mRx, mTx) = q(ConnectivityManager.TYPE_MOBILE)
        val (wRx, wTx) = q(ConnectivityManager.TYPE_WIFI)

        return mapOf(
            "mobileRx" to mRx,
            "mobileTx" to mTx,
            "wifiRx" to wRx,
            "wifiTx" to wTx
        )
    }
}
