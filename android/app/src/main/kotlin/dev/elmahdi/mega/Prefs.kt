package dev.elmahdi.mega

import android.content.Context
import android.content.SharedPreferences

/**
 * Single source of truth for reading Flutter SharedPreferences in Kotlin.
 *
 * Keys must match Dart's SettingsStore exactly, with the "flutter." prefix.
 * Dart `int` values are stored as Java `Long` in FlutterSharedPreferences.
 */
object Prefs {
    const val PREFS_NAME = "FlutterSharedPreferences"

    // Bundle keys
    const val KEY_BUNDLE_BYTES = "flutter.bundle_bytes"
    const val KEY_BUNDLE_START_MS = "flutter.bundle_start_ms"
    const val KEY_BUNDLE_VALIDITY_DAYS = "flutter.bundle_validity_days"
    const val KEY_BUNDLE_AUTO_RENEW = "flutter.bundle_auto_renew"
    const val KEY_BUNDLE_ID = "flutter.bundle_id"

    // Alerts & sync
    const val KEY_ALERTS_ENABLED = "flutter.alerts_enabled"
    const val KEY_ALERT_RULES = "flutter.alert_rules"
    const val KEY_SKIP_MOBILE_WARNING = "flutter.skip_mobile_warning"
    const val KEY_LAST_FULL_SYNC_MS = "flutter.last_full_sync_ms"

    fun get(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun getLong(prefs: SharedPreferences, key: String, def: Long = 0L): Long {
        return try {
            prefs.getLong(key, def)
        } catch (_: ClassCastException) {
            try {
                prefs.getInt(key, def.toInt()).toLong()
            } catch (_: Exception) {
                def
            }
        }
    }

    fun getInt(prefs: SharedPreferences, key: String, def: Int = 0): Int {
        return try {
            prefs.getInt(key, def)
        } catch (_: ClassCastException) {
            try {
                prefs.getLong(key, def.toLong()).toInt()
            } catch (_: Exception) {
                def
            }
        }
    }
}
