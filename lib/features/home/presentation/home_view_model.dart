import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/platform/usage_channel.dart';
import '../../../core/prefs/settings_store.dart';
import '../../../core/time/bundle_period.dart';
import '../../../core/time/day_range.dart';
import '../../speedtest/data/speed_test_engine.dart';
import '../../speedtest/data/speedtest_repository.dart';
import '../../speedtest/domain/speed_test_record.dart';
import '../../usage/data/usage_repository.dart';
import '../../usage/domain/past_bundle.dart';

class HomeViewModel extends ChangeNotifier {
  final UsageRepository usageRepository;
  final SpeedTestRepository speedRepository;
  final SettingsStore settings;
  final UsageSource? usageSource;

  HomeViewModel({
    required this.usageRepository,
    required this.speedRepository,
    required this.settings,
    this.usageSource,
  });

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasAccess = true;
  bool get hasAccess => _hasAccess;

  int _usedMobileBytes = 0;
  int get usedMobileBytes => _usedMobileBytes;

  int _usedWifiBytes = 0;
  int get usedWifiBytes => _usedWifiBytes;

  int _todayMobileBytes = 0;
  int get todayMobileBytes => _todayMobileBytes;

  int _todayWifiBytes = 0;
  int get todayWifiBytes => _todayWifiBytes;

  SpeedTestRecord? _lastSpeed;
  SpeedTestRecord? get lastSpeedResult => _lastSpeed;

  BundlePeriod _period = BundlePeriod(
    start: DateTime.now(),
    end: DateTime.now().add(const Duration(days: 30)),
    isExpired: false,
  );
  BundlePeriod get period => _period;

  int get totalBundleBytes => settings.bundleBytes;
  bool get hasBundle => totalBundleBytes > 0;
  bool get isBundleExpired => _period.isExpired;

  int get remainingBytes => isBundleExpired ? 0 : max(0, totalBundleBytes - _usedMobileBytes);

  double get usedPercentage {
    if (totalBundleBytes <= 0) return 0.0;
    if (isBundleExpired) return 1.0;
    return (_usedMobileBytes / totalBundleBytes).clamp(0.0, 1.0);
  }

  int get daysLeft => _period.daysLeft(DateTime.now());
  int get daysElapsed => _period.daysElapsed(DateTime.now());

  int get safeDailyAllowance => _period.safeDailyAllowance(remainingBytes, DateTime.now());

  PaceStatus get paceStatus => _period.calculatePace(
        usedBytes: _usedMobileBytes,
        totalBytes: totalBundleBytes,
        now: DateTime.now(),
      );

  // Quick Speed Test state on Home
  SpeedTestEngine? _quickEngine;
  StreamSubscription<SpeedTestProgress>? _quickSub;
  SpeedTestProgress? _quickProgress;
  SpeedTestProgress? get quickProgress => _quickProgress;
  bool _isQuickTesting = false;
  bool get isQuickTesting => _isQuickTesting;

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      _hasAccess = await usageRepository.usageSource.hasAccess();

      final now = DateTime.now();

      // Ensure bundleStartMs is initialized if user has a bundle configured
      if (settings.bundleBytes > 0 && settings.bundleStartMs <= 0) {
        settings.bundleStartMs = now.millisecondsSinceEpoch;
      }

      // Compute current period
      _period = BundlePeriod.compute(
        startMs: settings.bundleStartMs,
        validityDays: settings.bundleValidityDays,
        autoRenew: settings.bundleAutoRenew,
        now: now,
      );

      // If auto-renew rolled over to a new start date, update settings
      if (settings.bundleAutoRenew &&
          _period.start.millisecondsSinceEpoch != settings.bundleStartMs &&
          settings.bundleStartMs > 0) {
        // Record completed bundle to past bundles table
        await usageRepository.savePastBundle(PastBundle(
          id: settings.bundleId,
          startMs: settings.bundleStartMs,
          endMs: _period.start.millisecondsSinceEpoch,
          sizeBytes: totalBundleBytes,
          usedBytes: _usedMobileBytes,
        ));

        settings.bundleStartMs = _period.start.millisecondsSinceEpoch;
        settings.bundleId = settings.bundleId + 1;
      }

      // Query usage in current bundle period
      final totals = await usageRepository.getTotalsForRange(_period.start, _period.end);
      _usedMobileBytes = totals.mobileTotal;
      _usedWifiBytes = totals.wifiTotal;

      // Query today's usage (midnight to now)
      final todayStart = DayRange.startOfDay(now);
      final todayEnd = DayRange.endOfDay(now);
      final todayTotals = await usageRepository.getTotalsForRange(todayStart, todayEnd);
      _todayMobileBytes = todayTotals.mobileTotal;
      _todayWifiBytes = todayTotals.wifiTotal;

      // Query latest speed test
      _lastSpeed = await speedRepository.getLatest();
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> renewBundleNow({int? newBytes, int? newValidityDays}) async {
    final now = DateTime.now();
    // Archive current period
    if (settings.bundleBytes > 0 && settings.bundleStartMs > 0) {
      await usageRepository.savePastBundle(PastBundle(
        id: settings.bundleId,
        startMs: settings.bundleStartMs,
        endMs: now.millisecondsSinceEpoch,
        sizeBytes: totalBundleBytes,
        usedBytes: _usedMobileBytes,
      ));
    }

    settings.renewBundleNow(newBytes: newBytes, newValidityDays: newValidityDays);
    await refresh();
  }

  Future<void> runQuickTest() async {
    if (_isQuickTesting) return;
    _isQuickTesting = true;
    _quickProgress = const SpeedTestProgress(phase: SpeedTestPhase.pinging, progressPercent: 0.05);
    notifyListeners();

    _quickEngine = SpeedTestEngine();
    _quickSub = _quickEngine!.progressStream.listen((p) async {
      _quickProgress = p;
      notifyListeners();

      if (p.phase == SpeedTestPhase.completed) {
        final netType = await usageRepository.usageSource.networkType();
        final record = SpeedTestRecord(
          ts: DateTime.now().millisecondsSinceEpoch,
          pingMs: p.pingMs,
          jitterMs: p.jitterMs,
          downMbps: p.downMbps,
          upMbps: p.upMbps,
          networkType: netType,
          server: settings.testBaseUrl,
        );
        await speedRepository.insertTest(record);
        _lastSpeed = record;
        _isQuickTesting = false;
        notifyListeners();
      } else if (p.phase == SpeedTestPhase.failed || p.phase == SpeedTestPhase.cancelled) {
        _isQuickTesting = false;
        notifyListeners();
      }
    });

    await _quickEngine!.runTest(baseUrl: settings.testBaseUrl);
  }

  void cancelQuickTest() {
    _quickEngine?.cancel();
    _isQuickTesting = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _quickSub?.cancel();
    _quickEngine?.dispose();
    super.dispose();
  }
}
