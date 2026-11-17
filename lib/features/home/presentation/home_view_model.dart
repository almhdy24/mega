import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/prefs/settings_store.dart';
import '../../../core/time/billing_cycle.dart';
import '../../speedtest/data/speedtest_repository.dart';
import '../../speedtest/domain/speed_test_record.dart';
import '../../usage/data/usage_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final UsageRepository usageRepository;
  final SpeedTestRepository speedRepository;
  final SettingsStore settings;

  HomeViewModel({
    required this.usageRepository,
    required this.speedRepository,
    required this.settings,
  });

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _usedMobileBytes = 0;
  int get usedMobileBytes => _usedMobileBytes;

  int _usedWifiBytes = 0;
  int get usedWifiBytes => _usedWifiBytes;

  SpeedTestRecord? _lastSpeed;
  SpeedTestRecord? get lastSpeedResult => _lastSpeed;

  DateTime _cycleStart = DateTime.now();
  DateTime _cycleEnd = DateTime.now();

  int get totalBundleBytes => settings.bundleBytes;
  bool get hasBundle => totalBundleBytes > 0;

  int get remainingBytes => max(0, totalBundleBytes - _usedMobileBytes);

  double get usedPercentage {
    if (totalBundleBytes <= 0) return 0.0;
    return (_usedMobileBytes / totalBundleBytes).clamp(0.0, 1.0);
  }

  int get daysLeft {
    final now = DateTime.now();
    final diff = _cycleEnd.difference(now).inDays;
    return max(0, diff);
  }

  int get daysTotal {
    return max(1, _cycleEnd.difference(_cycleStart).inDays);
  }

  int get daysElapsed {
    final now = DateTime.now();
    return max(1, now.difference(_cycleStart).inDays);
  }

  int get dailyAverageBytes {
    return _usedMobileBytes ~/ daysElapsed;
  }

  int get dailyTargetBytes {
    final left = daysLeft;
    if (left <= 0) return remainingBytes;
    return remainingBytes ~/ left;
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final cycle = billingCycle(now, settings.cycleStartDay);
      _cycleStart = cycle.start;
      _cycleEnd = cycle.end;

      // Check for cycle alerts rollover
      if (settings.notifiedCycleStart != cycle.start.millisecondsSinceEpoch) {
        settings.resetCycleAlerts(cycle.start.millisecondsSinceEpoch);
      }

      // Query usage in current cycle
      final totals = await usageRepository.getTotalsForRange(cycle.start, cycle.end);
      _usedMobileBytes = totals.mobileTotal;
      _usedWifiBytes = totals.wifiTotal;

      // Query latest speed test
      _lastSpeed = await speedRepository.getLatest();

      // Check alert thresholds
      if (settings.alertsEnabled && hasBundle) {
        final crossed = newlyCrossed(
          usedBytes: _usedMobileBytes,
          bundleBytes: totalBundleBytes,
          thresholds: settings.alertThresholds,
          alreadyNotified: settings.notifiedThresholds,
        );
        for (final t in crossed) {
          settings.markThresholdNotified(t);
        }
      }
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
