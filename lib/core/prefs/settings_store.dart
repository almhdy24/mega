import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../time/billing_cycle.dart';

class SettingsStore extends ChangeNotifier {
  final SharedPreferences _prefs;

  SettingsStore(this._prefs) {
    _migrateLegacyCycleStartDay();
  }

  static const String keyBundleBytes = 'bundle_bytes';
  static const String keyBundleStartMs = 'bundle_start_ms';
  static const String keyBundleValidityDays = 'bundle_validity_days';
  static const String keyBundleAutoRenew = 'bundle_auto_renew';
  static const String keyBundleId = 'bundle_id';
  static const String keyCycleStartDay = 'cycle_start_day';
  static const String keyAlertThresholds = 'alert_thresholds';
  static const String keyAlertsEnabled = 'alerts_enabled';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLocale = 'locale';
  static const String keyTestBaseUrl = 'test_base_url';
  static const String keyNotifiedCycleStart = 'notified_cycle_start';
  static const String keyNotifiedThresholds = 'notified_thresholds';
  static const String keySkipMobileWarning = 'skip_mobile_warning';
  static const String keyLastFullSyncMs = 'last_full_sync_ms';

  static const String defaultTestBaseUrl = 'https://fra.speedtest.clouvider.net/backend';

  void _migrateLegacyCycleStartDay() {
    if (_prefs.containsKey(keyCycleStartDay) && !_prefs.containsKey(keyBundleStartMs)) {
      final oldDay = _prefs.getInt(keyCycleStartDay) ?? 1;
      final cycle = billingCycle(DateTime.now(), oldDay);
      _prefs.setInt(keyBundleStartMs, cycle.start.millisecondsSinceEpoch);
      _prefs.setInt(keyBundleValidityDays, 30);
      _prefs.setBool(keyBundleAutoRenew, true);
      _prefs.setInt(keyBundleId, 1);
      _prefs.remove(keyCycleStartDay);
    }
  }

  int get bundleBytes => _prefs.getInt(keyBundleBytes) ?? 0;
  set bundleBytes(int value) {
    _prefs.setInt(keyBundleBytes, value);
    notifyListeners();
  }

  int get bundleStartMs => _prefs.getInt(keyBundleStartMs) ?? 0;
  set bundleStartMs(int value) {
    _prefs.setInt(keyBundleStartMs, value);
    notifyListeners();
  }

  int get bundleValidityDays => _prefs.getInt(keyBundleValidityDays) ?? 30;
  set bundleValidityDays(int value) {
    _prefs.setInt(keyBundleValidityDays, max(1, value));
    notifyListeners();
  }

  bool get bundleAutoRenew => _prefs.getBool(keyBundleAutoRenew) ?? true;
  set bundleAutoRenew(bool value) {
    _prefs.setBool(keyBundleAutoRenew, value);
    notifyListeners();
  }

  int get bundleId => _prefs.getInt(keyBundleId) ?? 1;
  set bundleId(int value) {
    _prefs.setInt(keyBundleId, value);
    notifyListeners();
  }

  void renewBundleNow({int? newBytes, int? newValidityDays}) {
    final nextId = bundleId + 1;
    _prefs.setInt(keyBundleId, nextId);
    _prefs.setInt(keyBundleStartMs, DateTime.now().millisecondsSinceEpoch);
    if (newBytes != null) _prefs.setInt(keyBundleBytes, newBytes);
    if (newValidityDays != null) _prefs.setInt(keyBundleValidityDays, max(1, newValidityDays));
    _prefs.setString(keyNotifiedThresholds, '[]');
    notifyListeners();
  }

  int get cycleStartDay => _prefs.getInt(keyCycleStartDay) ?? 1;
  set cycleStartDay(int value) {
    _prefs.setInt(keyCycleStartDay, value.clamp(1, 31));
    notifyListeners();
  }

  List<int> get alertThresholds {
    final raw = _prefs.getString(keyAlertThresholds);
    if (raw == null || raw.isEmpty) return const [50, 80, 100];
    try {
      final list = (jsonDecode(raw) as List).map((e) => e as int).toList();
      return list..sort();
    } catch (_) {
      return const [50, 80, 100];
    }
  }

  set alertThresholds(List<int> values) {
    _prefs.setString(keyAlertThresholds, jsonEncode(values..sort()));
    notifyListeners();
  }

  bool get alertsEnabled => _prefs.getBool(keyAlertsEnabled) ?? true;
  set alertsEnabled(bool value) {
    _prefs.setBool(keyAlertsEnabled, value);
    notifyListeners();
  }

  ThemeMode get themeMode {
    final raw = _prefs.getString(keyThemeMode);
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  set themeMode(ThemeMode mode) {
    String val = 'system';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.dark) val = 'dark';
    _prefs.setString(keyThemeMode, val);
    notifyListeners();
  }

  Locale? get locale {
    final raw = _prefs.getString(keyLocale);
    if (raw == 'en') return const Locale('en');
    if (raw == 'ar') return const Locale('ar');
    return const Locale('ar'); // Arabic is default
  }

  set locale(Locale? loc) {
    if (loc == null) {
      _prefs.remove(keyLocale);
    } else {
      _prefs.setString(keyLocale, loc.languageCode);
    }
    notifyListeners();
  }

  String get testBaseUrl => _prefs.getString(keyTestBaseUrl) ?? defaultTestBaseUrl;
  set testBaseUrl(String value) {
    _prefs.setString(keyTestBaseUrl, value.trim());
    notifyListeners();
  }

  int get notifiedCycleStart => _prefs.getInt(keyNotifiedCycleStart) ?? 0;
  set notifiedCycleStart(int epochMs) {
    _prefs.setInt(keyNotifiedCycleStart, epochMs);
  }

  bool get skipMobileWarning => _prefs.getBool(keySkipMobileWarning) ?? false;
  set skipMobileWarning(bool value) {
    _prefs.setBool(keySkipMobileWarning, value);
    notifyListeners();
  }

  int get lastFullSyncMs => _prefs.getInt(keyLastFullSyncMs) ?? 0;
  set lastFullSyncMs(int value) {
    _prefs.setInt(keyLastFullSyncMs, value);
    notifyListeners();
  }

  Set<int> get notifiedThresholds {
    final raw = _prefs.getString(keyNotifiedThresholds);
    if (raw == null || raw.isEmpty) return <int>{};
    try {
      final list = (jsonDecode(raw) as List).map((e) => e as int).toSet();
      return list;
    } catch (_) {
      return <int>{};
    }
  }

  set notifiedThresholds(Set<int> values) {
    _prefs.setString(keyNotifiedThresholds, jsonEncode(values.toList()..sort()));
  }

  void markThresholdNotified(int threshold) {
    final current = notifiedThresholds..add(threshold);
    notifiedThresholds = current;
  }

  void resetCycleAlerts(int newCycleStartEpochMs) {
    notifiedCycleStart = newCycleStartEpochMs;
    notifiedThresholds = <int>{};
  }
}
