package dev.elmahdi.mega

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        UsagePlugin.registerWith(flutterEngine.dartExecutor.binaryMessenger, applicationContext)
    }
}
