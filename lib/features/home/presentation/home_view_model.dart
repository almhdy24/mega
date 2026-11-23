import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/platform/live_monitor_channel.dart';
import '../../../core/platform/usage_channel.dart';
import '../../../core/prefs/settings_store.dart';
import '../../../core/time/bundle_period.dart';
import '../../../core/time/day_range.dart';
import '../../usage/data/usage_repository.dart';
import '../../usage/domain/daily_usage.dart';
import '../../usage/domain/past_bundle.dart';

class HomeViewModel extends ChangeNotifier {
  final UsageRepository usageRepository;
  final SettingsStore settings;
  final UsageSource? usageSource;

  HomeViewModel({
    required this.usageRepository,
    required this.settings,
    this.usageSource,
  });

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void>? _activeRefreshFuture;
  bool _hasQueuedRefresh = false;

  bool _hasAccess = true;
  bool get hasAccess => _hasAccess;

  bool _hasNotificationAccess = true;
  bool get hasNotificationAccess => _hasNotificationAccess;

  UsageResultStatus _syncStatus = UsageResultStatus.ok;
  UsageResultStatus get syncStatus => _syncStatus;

  int _usedMobileBytes = 0;
  int get usedMobileBytes => _usedMobileBytes;

  int _usedWifiBytes = 0;
  int get usedWifiBytes => _usedWifiBytes;

  int _todayMobileBytes = 0;
  int get todayMobileBytes => _todayMobileBytes;

  int _todayWifiBytes = 0;
  int get todayWifiBytes => _todayWifiBytes;

  int _historyDays = 7;
  int get historyDays => _historyDays;

  List<DailyUsage> _historyData = const [];
  List<DailyUsage> get historyData => _historyData;

  int get historyMobileTotal => _historyData.fold(0, (sum, d) => sum + d.mobileTotal);
  int get historyWifiTotal => _historyData.fold(0, (sum, d) => sum + d.wifiTotal);

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

  DateTime? get lastSyncDateTime {
    if (settings.lastFullSyncMs <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(settings.lastFullSyncMs);
  }

  bool get isDataOutdated {
    if (settings.lastFullSyncMs <= 0) return true;
    final diff = DateTime.now().millisecondsSinceEpoch - settings.lastFullSyncMs;
    return diff > (24 * 60 * 60 * 1000);
  }

  Future<void> setHistoryDays(int days) async {
    if (_historyDays == days && _historyData.isNotEmpty) return;
    _historyDays = days;
    _historyData = await usageRepository.getDailyHistory(days: days, referenceNow: DateTime.now());
    notifyListeners();
  }

  Future<void> openSettings() async {
    await usageRepository.usageSource.openAccessSettings();
  }

  Future<void> refresh() async {
    if (_activeRefreshFuture != null) {
      _hasQueuedRefresh = true;
      await _activeRefreshFuture;
      return;
    }

    _isLoading = true;
    notifyListeners();

    _activeRefreshFuture = _executeRefreshLoop();
    try {
      await _activeRefreshFuture;
    } finally {
      _activeRefreshFuture = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _executeRefreshLoop() async {
    do {
      _hasQueuedRefresh = false;
      await _performRefresh();
    } while (_hasQueuedRefresh);
  }

  Future<void> _performRefresh() async {
    try {
      _hasAccess = await usageRepository.usageSource.hasAccess();
      _hasNotificationAccess = await LiveMonitorChannel.hasNotificationPermission();

      // Auto enable live notification in status bar by default if permissions are available
      if (settings.liveMonitorEnabled && _hasNotificationAccess) {
        final isRunning = await LiveMonitorChannel.isRunning();
        if (!isRunning) {
          await LiveMonitorChannel.start();
        }
      }

      final now = DateTime.now();

      // Ensure bundleStartMs is initialized if user has a bundle configured
      if (settings.bundleBytes > 0 && settings.bundleStartMs <= 0) {
        settings.bundleStartMs = now.millisecondsSinceEpoch;
      }

      // Synchronize usage from Android system first if access is granted
      if (_hasAccess) {
        _syncStatus = await usageRepository.syncAdaptive(
          lastFullSyncMs: settings.lastFullSyncMs,
          onFullSyncSuccess: (ms) => settings.lastFullSyncMs = ms,
          referenceNow: now,
        );
      } else {
        _syncStatus = UsageResultStatus.denied;
      }

      // Handle bundle auto-renew rollover across all completed periods
      if (settings.bundleAutoRenew &&
          settings.bundleBytes > 0 &&
          settings.bundleStartMs > 0) {
        final validityDays = max(1, settings.bundleValidityDays);
        final validityDuration = Duration(days: validityDays);
        var curStart = DateTime.fromMillisecondsSinceEpoch(settings.bundleStartMs);
        var curEnd = curStart.add(validityDuration);
        var curId = settings.bundleId;

        while (now.isAfter(curEnd) || now.isAtSameMomentAs(curEnd)) {
          // Query usage for the completed period (mobile only, wifi excluded)
          final totals = await usageRepository.getTotalsForRange(curStart, curEnd);

          await usageRepository.savePastBundle(PastBundle(
            id: curId,
            startMs: curStart.millisecondsSinceEpoch,
            endMs: curEnd.millisecondsSinceEpoch,
            sizeBytes: totalBundleBytes,
            usedBytes: totals.mobileTotal,
          ));

          curStart = curEnd;
          curEnd = curStart.add(validityDuration);
          curId++;

          // Update settings after successful archival of this period
          settings.bundleStartMs = curStart.millisecondsSinceEpoch;
          settings.bundleId = curId;
        }
      }

      // Compute current active period
      _period = BundlePeriod.compute(
        startMs: settings.bundleStartMs,
        validityDays: settings.bundleValidityDays,
        autoRenew: settings.bundleAutoRenew,
        now: now,
      );

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

      // Query history for selected period (7 or 30 days)
      _historyData = await usageRepository.getDailyHistory(days: _historyDays, referenceNow: now);
    } catch (_) {
      _syncStatus = UsageResultStatus.error;
    }
  }

  Future<void> renewBundleNow({int? newBytes, int? newValidityDays}) async {
    final now = DateTime.now();
    // Archive current period with actual mobile usage
    if (settings.bundleBytes > 0 && settings.bundleStartMs > 0) {
      final start = DateTime.fromMillisecondsSinceEpoch(settings.bundleStartMs);
      final totals = await usageRepository.getTotalsForRange(start, now);
      await usageRepository.savePastBundle(PastBundle(
        id: settings.bundleId,
        startMs: settings.bundleStartMs,
        endMs: now.millisecondsSinceEpoch,
        sizeBytes: totalBundleBytes,
        usedBytes: totals.mobileTotal,
      ));
    }

    settings.renewBundleNow(newBytes: newBytes, newValidityDays: newValidityDays);
    await refresh();
  }
}
