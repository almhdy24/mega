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
    notifyListeners();

    try {
      _hasAccess = await repository.usageSource.hasAccess();

      if (_hasAccess) {
        // Sync system usage into SQLite
        await repository.syncSnapshots(days: 35);
      }

      final now = DateTime.now();

      // Today
      final todayStart = DayRange.startOfDay(now);
      final todayEnd = DayRange.endOfDay(now);
      _today = await repository.getTotalsForRange(todayStart, todayEnd);

      // This Cycle
      final cycle = billingCycle(now, settings.cycleStartDay);
      _cycle = await repository.getTotalsForRange(cycle.start, cycle.end);

      // This Month (1st of month to 1st of next month)
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 1);
      _month = await repository.getTotalsForRange(monthStart, monthEnd);

      // 30 days chart
      _chartData = await repository.getLast30Days(referenceNow: now);
    } catch (_) {
      // Graceful error state handling
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> openSettings() async {
    await repository.usageSource.openAccessSettings();
  }
}
