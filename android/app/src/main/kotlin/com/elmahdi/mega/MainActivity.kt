package com.elmahdi.mega

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    companion object {
        var currentActivity: MainActivity? = null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Enable edge-to-edge system window fitting
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }

    override fun onResume() {
        super.onResume()
        currentActivity = this
    }

    override fun onPause() {
        super.onPause()
        if (currentActivity == this) {
            currentActivity = null
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        UsagePlugin.registerWith(flutterEngine.dartExecutor.binaryMessenger, applicationContext)
        LiveMonitorPlugin.registerWith(flutterEngine.dartExecutor.binaryMessenger, applicationContext)
    }
}
