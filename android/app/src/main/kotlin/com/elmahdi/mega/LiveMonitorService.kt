package com.elmahdi.mega

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.TrafficStats
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.graphics.drawable.IconCompat
import java.util.Calendar
import java.util.Locale

class LiveMonitorService : Service() {

    companion object {
        const val CHANNEL_ID = "live_speed"
        const val CHANNEL_NAME = "عداد السرعة الحي | Live Speed"
        const val NOTIFICATION_ID = 1001

        const val ACTION_START = "com.elmahdi.mega.START_MONITOR"
        const val ACTION_STOP = "com.elmahdi.mega.STOP_MONITOR"
        const val ACTION_APPLY = "com.elmahdi.mega.APPLY_SETTINGS"

        @Volatile
        var isRunning: Boolean = false
            private set

        fun start(context: Context) {
            val intent = Intent(context, LiveMonitorService::class.java).apply {
                action = ACTION_START
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, LiveMonitorService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }

        fun apply(context: Context) {
            val intent = Intent(context, LiveMonitorService::class.java).apply {
                action = ACTION_APPLY
            }
            context.startService(intent)
        }
    }

    private var handlerThread: HandlerThread? = null
    private var handler: Handler? = null

    private var screenReceiver: BroadcastReceiver? = null
    private var isScreenOn = true

    // Sampling state
    private var lastRxBytes = 0L
    private var lastTxBytes = 0L
    private var lastSampleTimeMs = 0L

    // Cached usage
    private var lastUsageQueryMs = 0L
    private var cachedTodayMobileBytes = 0L
    private var cachedBundleRemainingBytes = 0L
    private var cachedDaysLeft = 0

    // Settings cached
    private var intervalMs = 2000L
    private var isBits = false
    private var isMobileOnly = true
    private var isDynamicIcon = true
    private var isScreenOffUpdate = false
    private var isHideOnWifi = false

    private val tickRunnable = object : Runnable {
        override fun run() {
            if (!isRunning) return
            onTick()
            val nextDelay = if (!isScreenOn && !isScreenOffUpdate) 300_000L else intervalMs
            handler?.postDelayed(this, nextDelay)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        createNotificationChannel()
        loadSettings()

        val thread = HandlerThread("MegaLiveMonitorThread").apply { start() }
        handlerThread = thread
        handler = Handler(thread.looper)

        registerScreenReceiver()

        // Init traffic baselines
        val initialTraffic = queryTrafficBytes()
        lastRxBytes = initialTraffic.first
        lastTxBytes = initialTraffic.second
        lastSampleTimeMs = System.currentTimeMillis()

        // Immediate initial notification
        startForegroundServiceInternal(buildNotification(0L, 0L))
        handler?.post(tickRunnable)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                // User clicked "Stop" action from notification
                val prefs = Prefs.get(this)
                prefs.edit().putBoolean(Prefs.KEY_LIVE_MONITOR_ENABLED, false).apply()
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_APPLY -> {
                loadSettings()
            }
        }
        return START_STICKY
    }

    private fun loadSettings() {
        val prefs = Prefs.get(this)
        val sec = Prefs.getInt(prefs, Prefs.KEY_LIVE_MONITOR_INTERVAL_SEC, 2).coerceIn(1, 10)
        intervalMs = sec * 1000L

        val unit = prefs.getString(Prefs.KEY_LIVE_MONITOR_UNIT, "bytes") ?: "bytes"
        isBits = unit == "bits"

        isMobileOnly = prefs.getBoolean(Prefs.KEY_LIVE_MONITOR_MOBILE_ONLY, true)
        val iconStyle = prefs.getString(Prefs.KEY_LIVE_MONITOR_ICON_STYLE, "dynamic") ?: "dynamic"
        isDynamicIcon = iconStyle == "dynamic"

        isScreenOffUpdate = prefs.getBoolean(Prefs.KEY_LIVE_MONITOR_SCREEN_OFF, false)
        isHideOnWifi = prefs.getBoolean(Prefs.KEY_LIVE_MONITOR_HIDE_ON_WIFI, false)
    }

    private fun registerScreenReceiver() {
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
        }
        screenReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    Intent.ACTION_SCREEN_ON -> {
                        isScreenOn = true
                        handler?.removeCallbacks(tickRunnable)
                        handler?.post(tickRunnable)
                    }
                    Intent.ACTION_SCREEN_OFF -> {
                        isScreenOn = false
                        if (!isScreenOffUpdate) {
                            handler?.removeCallbacks(tickRunnable)
                            handler?.postDelayed(tickRunnable, 300_000L) // Slow 5-min tick
                        }
                    }
                }
            }
        }
        registerReceiver(screenReceiver, filter)
    }

    private fun onTick() {
        val now = System.currentTimeMillis()
        val dtSec = (now - lastSampleTimeMs) / 1000.0

        val (currentRx, currentTx) = queryTrafficBytes()

        var rxSpeed = 0L
        var txSpeed = 0L

        if (dtSec > 0 && lastRxBytes > 0 && currentRx >= lastRxBytes) {
            rxSpeed = ((currentRx - lastRxBytes) / dtSec).toLong()
            txSpeed = ((currentTx - lastTxBytes) / dtSec).toLong()
        }

        lastRxBytes = currentRx
        lastTxBytes = currentTx
        lastSampleTimeMs = now

        // Check WiFi hide rule
        if (isHideOnWifi && isConnectedToWifi()) {
            return
        }

        // Refresh usage every 30 seconds
        if (now - lastUsageQueryMs >= 30_000L || lastUsageQueryMs == 0L) {
            refreshUsageStats(now)
            lastUsageQueryMs = now
        }

        val notification = buildNotification(rxSpeed, txSpeed)
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        manager?.notify(NOTIFICATION_ID, notification)
    }

    private fun queryTrafficBytes(): Pair<Long, Long> {
        val rx: Long
        val tx: Long
        if (isMobileOnly) {
            val mRx = TrafficStats.getMobileRxBytes()
            val mTx = TrafficStats.getMobileTxBytes()
            if (mRx != TrafficStats.UNSUPPORTED.toLong() && mTx != TrafficStats.UNSUPPORTED.toLong()) {
                rx = mRx
                tx = mTx
            } else {
                rx = TrafficStats.getTotalRxBytes()
                tx = TrafficStats.getTotalTxBytes()
            }
        } else {
            rx = TrafficStats.getTotalRxBytes()
            tx = TrafficStats.getTotalTxBytes()
        }
        return Pair(rx.coerceAtLeast(0L), tx.coerceAtLeast(0L))
    }

    private fun isConnectedToWifi(): Boolean {
        return try {
            val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
            val net = cm?.activeNetwork ?: return false
            val caps = cm.getNetworkCapabilities(net) ?: return false
            caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
        } catch (_: Exception) {
            false
        }
    }

    private fun refreshUsageStats(now: Long) {
        try {
            val cal = Calendar.getInstance().apply {
                timeInMillis = now
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            val startOfDay = cal.timeInMillis

            val range = UsageQuery.range(this, startOfDay, now)
            val dailyMobile = UsageQuery.parseMobileBytes(range)
            if (dailyMobile != null) {
                cachedTodayMobileBytes = dailyMobile
            }

            // Compute bundle remaining
            val prefs = Prefs.get(this)
            val bundleBytes = Prefs.getLong(prefs, Prefs.KEY_BUNDLE_BYTES, 0L)
            val bundleStartMs = Prefs.getLong(prefs, Prefs.KEY_BUNDLE_START_MS, 0L)
            val validityDays = Prefs.getInt(prefs, Prefs.KEY_BUNDLE_VALIDITY_DAYS, 30)
            val autoRenew = prefs.getBoolean(Prefs.KEY_BUNDLE_AUTO_RENEW, true)

            if (bundleBytes > 0 && bundleStartMs > 0) {
                val period = BundlePeriod.compute(bundleStartMs, validityDays, autoRenew, now)
                val periodRange = UsageQuery.range(this, period.startMs, now)
                val periodMobile = UsageQuery.parseMobileBytes(periodRange)
                if (periodMobile != null) {
                    cachedBundleRemainingBytes = (bundleBytes - periodMobile).coerceAtLeast(0L)
                }
                cachedDaysLeft = period.daysLeft(now)
            } else {
                cachedBundleRemainingBytes = 0L
                cachedDaysLeft = 0
            }
        } catch (_: Exception) {}
    }

    private fun buildNotification(rxSpeedBytesPerSec: Long, txSpeedBytesPerSec: Long): Notification {
        val title = formatSpeedTitle(rxSpeedBytesPerSec, txSpeedBytesPerSec)
        val text = formatUsageText()

        // Tap opens MainActivity
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openPending = PendingIntent.getActivity(
            this,
            1,
            openIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        // Stop Service Action
        val stopIntent = Intent(this, LiveMonitorService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPending = PendingIntent.getService(
            this,
            3,
            stopIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(openPending)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .addAction(0, "إيقاف", stopPending)

        // Set Dynamic Icon or Static Icon
        val totalSpeed = rxSpeedBytesPerSec + txSpeedBytesPerSec
        if (isDynamicIcon) {
            val iconText = formatCompactSpeed(totalSpeed)
            val bitmap = createSpeedBitmap(iconText)
            if (bitmap != null) {
                builder.setSmallIcon(IconCompat.createWithBitmap(bitmap))
            } else {
                builder.setSmallIcon(R.mipmap.ic_launcher)
            }
        } else {
            builder.setSmallIcon(R.mipmap.ic_launcher)
        }

        return builder.build()
    }

    private fun formatSpeedTitle(rxSpeed: Long, txSpeed: Long): String {
        return if (isBits) {
            val rxBits = rxSpeed * 8.0
            val txBits = txSpeed * 8.0
            "↓ ${formatBits(rxBits)}   ↑ ${formatBits(txBits)}"
        } else {
            "↓ ${formatBytes(rxSpeed)}/s   ↑ ${formatBytes(txSpeed)}/s"
        }
    }

    private fun formatUsageText(): String {
        val todayStr = formatBytes(cachedTodayMobileBytes)
        if (cachedBundleRemainingBytes > 0) {
            val remStr = formatBytes(cachedBundleRemainingBytes)
            return "اليوم $todayStr · متبقي $remStr · $cachedDaysLeft أيام"
        }
        return "اليوم $todayStr"
    }

    private fun formatBytes(bytes: Long): String {
        if (bytes < 1024) return "$bytes B"
        val kb = bytes / 1024.0
        if (kb < 1024) return String.format(Locale.US, "%.1f KB", kb)
        val mb = kb / 1024.0
        if (mb < 1024) return String.format(Locale.US, "%.1f MB", mb)
        val gb = mb / 1024.0
        return String.format(Locale.US, "%.2f GB", gb)
    }

    private fun formatBits(bits: Double): String {
        if (bits < 1000) return "${bits.toInt()} bps"
        val kbps = bits / 1000.0
        if (kbps < 1000) return String.format(Locale.US, "%.0f Kbps", kbps)
        val mbps = kbps / 1000.0
        return String.format(Locale.US, "%.1f Mbps", mbps)
    }

    private fun formatCompactSpeed(bytesPerSec: Long): String {
        if (bytesPerSec <= 0) return "0K"
        val kb = bytesPerSec / 1024.0
        return if (kb < 1000) {
            "${kb.toInt()}K"
        } else {
            val mb = kb / 1024.0
            String.format(Locale.US, "%.1fM", mb)
        }
    }

    private fun createSpeedBitmap(text: String): Bitmap? {
        return try {
            val size = 64
            val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            canvas.drawColor(Color.TRANSPARENT)

            val paint = Paint().apply {
                isAntiAlias = true
                color = Color.WHITE
                textAlign = Paint.Align.CENTER
                typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                textSize = if (text.length <= 2) 36f else (if (text.length == 3) 28f else 22f)
            }

            val yPos = (size / 2 - (paint.descent() + paint.ascent()) / 2)
            canvas.drawText(text, size / 2f, yPos, paint)
            bitmap
        } catch (_: Exception) {
            null
        }
    }

    private fun startForegroundServiceInternal(notification: Notification) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                ServiceCompat.startForeground(
                    this,
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (_: Exception) {
            try {
                startForeground(NOTIFICATION_ID, notification)
            } catch (_: Exception) {}
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "عرض عداد السرعة الحي واستهلاك البيانات في شريط الحالة"
                setShowBadge(false)
                enableLights(false)
                enableVibration(false)
                setSound(null, null)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            manager?.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        isRunning = false
        handler?.removeCallbacksAndMessages(null)
        handlerThread?.quitSafely()
        handlerThread = null
        handler = null

        screenReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (_: Exception) {}
            screenReceiver = null
        }

        super.onDestroy()
    }
}
