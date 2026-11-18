package com.elmahdi.mega

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class LiveMonitorPlugin(private val ctx: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "com.elmahdi.mega/live_monitor"

        fun registerWith(messenger: BinaryMessenger, context: Context) {
            val channel = MethodChannel(messenger, CHANNEL_NAME)
            val plugin = LiveMonitorPlugin(context.applicationContext)
            channel.setMethodCallHandler(plugin)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                try {
                    LiveMonitorService.start(ctx)
                    result.success(true)
                } catch (t: Throwable) {
                    result.error("START_FAILED", t.message, null)
                }
            }
            "stop" -> {
                try {
                    LiveMonitorService.stop(ctx)
                    result.success(true)
                } catch (t: Throwable) {
                    result.error("STOP_FAILED", t.message, null)
                }
            }
            "apply" -> {
                try {
                    LiveMonitorService.apply(ctx)
                    result.success(true)
                } catch (t: Throwable) {
                    result.error("APPLY_FAILED", t.message, null)
                }
            }
            "isRunning" -> {
                result.success(LiveMonitorService.isRunning)
            }
            "hasNotificationPermission" -> {
                val enabled = NotificationManagerCompat.from(ctx).areNotificationsEnabled()
                result.success(enabled)
            }
            "requestNotificationPermission" -> {
                if (Build.VERSION.SDK_INT >= 33) {
                    val act = MainActivity.currentActivity
                    if (act != null) {
                        ActivityCompat.requestPermissions(
                            act,
                            arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                            1002
                        )
                        result.success(true)
                    } else {
                        try {
                            val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                                putExtra(Settings.EXTRA_APP_PACKAGE, ctx.packageName)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            ctx.startActivity(intent)
                            result.success(true)
                        } catch (_: Exception) {
                            result.success(false)
                        }
                    }
                } else {
                    result.success(true)
                }
            }
            "openNotificationSettings" -> {
                try {
                    val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                        putExtra(Settings.EXTRA_APP_PACKAGE, ctx.packageName)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    ctx.startActivity(intent)
                    result.success(true)
                } catch (_: Exception) {
                    try {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.parse("package:${ctx.packageName}")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        ctx.startActivity(intent)
                        result.success(true)
                    } catch (t: Throwable) {
                        result.error("INTENT_FAILED", t.message, null)
                    }
                }
            }
            "openBatterySettings" -> {
                try {
                    val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    ctx.startActivity(intent)
                    result.success(true)
                } catch (_: Exception) {
                    try {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.parse("package:${ctx.packageName}")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        ctx.startActivity(intent)
                        result.success(true)
                    } catch (t: Throwable) {
                        result.error("INTENT_FAILED", t.message, null)
                    }
                }
            }
            "openAppDetailsSettings" -> {
                try {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.parse("package:${ctx.packageName}")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    ctx.startActivity(intent)
                    result.success(true)
                } catch (t: Throwable) {
                    result.error("INTENT_FAILED", t.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }
}
