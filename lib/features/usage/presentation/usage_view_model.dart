import 'package:flutter/material.dart';
import '../../../core/platform/usage_channel.dart';
import '../../../core/prefs/settings_store.dart';
import '../../../core/time/billing_cycle.dart';
import '../../../core/time/day_range.dart';
import '../data/usage_repository.dart';
import '../domain/daily_usage.dart';

class UsageViewModel extends ChangeNotifier {
  final UsageRepository repository;
  final SettingsStore settings;

  UsageViewModel({
    required this.repository,
    required this.settings,
  });

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasAccess = false;
  bool get hasAccess => _hasAccess;

  bool _isMobileSupported = true;
  bool get isMobileSupported => _isMobileSupported;

  UsageResultStatus _status = UsageResultStatus.ok;
  UsageResultStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UsageTotals _today = const UsageTotals.zero();
  UsageTotals get todayTotals => _today;

  UsageTotals _cycle = const UsageTotals.zero();
  UsageTotals get cycleTotals => _cycle;

  UsageTotals _month = const UsageTotals.zero();
  UsageTotals get monthTotals => _month;

  List<DailyUsage> _chartData = [];
  List<DailyUsage> get chartData => _chartData;

  Future<void> init() async {
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _hasAccess = await repository.usageSource.hasAccess();
      if (!_hasAccess) {
        _status = UsageResultStatus.denied;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final now = DateTime.now();

      // Check if mobile stats are supported on this Android OS version
      final check = await repository.usageSource.queryRange(
        DayRange.startOfDay(now),
        DayRange.endOfDay(now),
      );
      _isMobileSupported = check.totals.mobileSupported;
      if (check.status == UsageResultStatus.unsupported) {
        _status = UsageResultStatus.unsupported;
      } else if (check.status == UsageResultStatus.error) {
        _status = UsageResultStatus.error;
        _errorMessage = check.message;
      } else {
        _status = UsageResultStatus.ok;
      }

      // Adaptive sync: full 35-day sync only once per day or when DB is empty.
      // Normal refresh syncs only today and yesterday (days: 2).
      final isDbEmpty = await repository.isUsageEmpty();
      const oneDayMs = 24 * 60 * 60 * 1000;
      final shouldFullSync =
          isDbEmpty || (now.millisecondsSinceEpoch - settings.lastFullSyncMs > oneDayMs);

      if (shouldFullSync) {
        final syncStatus = await repository.syncSnapshots(days: 35, referenceNow: now);
        if (syncStatus == UsageResultStatus.ok || syncStatus == UsageResultStatus.unsupported) {
          settings.lastFullSyncMs = now.millisecondsSinceEpoch;
        }
      } else {
        await repository.syncSnapshots(days: 2, referenceNow: now);
      }

      // Today
      final todayStart = DayRange.startOfDay(now);
      final todayEnd = DayRange.endOfDay(now);
      final todayData = await repository.getTotalsForRange(todayStart, todayEnd);
      _today = todayData.copyWith(mobileSupported: _isMobileSupported);

      // This Cycle
      final cycle = billingCycle(now, settings.cycleStartDay);
      final cycleData = await repository.getTotalsForRange(cycle.start, cycle.end);
      _cycle = cycleData.copyWith(mobileSupported: _isMobileSupported);

      // This Month (1st of month to 1st of next month)
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 1);
      final monthData = await repository.getTotalsForRange(monthStart, monthEnd);
      _month = monthData.copyWith(mobileSupported: _isMobileSupported);

      // 30 days chart
      _chartData = await repository.getLast30Days(referenceNow: now);
    } catch (e) {
      _status = UsageResultStatus.error;
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> openSettings() async {
    await repository.usageSource.openAccessSettings();
  }
}
