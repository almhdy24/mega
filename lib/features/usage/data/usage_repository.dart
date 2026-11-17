import 'package:sqflite/sqflite.dart';
import '../../../core/platform/usage_channel.dart';
import '../../../core/time/day_range.dart';
import '../domain/daily_usage.dart';

class UsageRepository {
  final Database db;
  final UsageSource usageSource;

  UsageRepository({
    required this.db,
    required this.usageSource,
  });

  /// Snapshot rule: queries the system for the last [days] days (default 35)
  /// and upserts into usage_daily using MAX(existing, new) per column.
  /// A day that later reads 0 (history expired) will never overwrite a non-zero stored value.
  Future<void> syncSnapshots({int days = 35, DateTime? referenceNow}) async {
    final hasAccess = await usageSource.hasAccess();
    if (!hasAccess) return;

    final now = referenceNow ?? DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    // Use a transaction/batch for performance and atomicity
    await db.transaction((txn) async {
      for (var i = 0; i < days; i++) {
        final targetDate = now.subtract(Duration(days: i));
        final dayStr = DayRange.formatDay(targetDate);
        final startLocal = DayRange.startOfDay(targetDate);
        final endLocal = DayRange.endOfDay(targetDate);

        final totals = await usageSource.queryRange(startLocal, endLocal);

        // Upsert with MAX logic
        await txn.rawInsert('''
          INSERT INTO usage_daily (day, mobile_rx, mobile_tx, wifi_rx, wifi_tx, updated_at)
          VALUES (?, ?, ?, ?, ?, ?)
          ON CONFLICT(day) DO UPDATE SET
            mobile_rx = MAX(usage_daily.mobile_rx, excluded.mobile_rx),
            mobile_tx = MAX(usage_daily.mobile_tx, excluded.mobile_tx),
            wifi_rx = MAX(usage_daily.wifi_rx, excluded.wifi_rx),
            wifi_tx = MAX(usage_daily.wifi_tx, excluded.wifi_tx),
            updated_at = excluded.updated_at
        ''', [
          dayStr,
          totals.mobileRx,
          totals.mobileTx,
          totals.wifiRx,
          totals.wifiTx,
          nowMs,
        ]);
      }
    });
  }

  /// Get daily usage entry for a specific 'YYYY-MM-DD'
  Future<DailyUsage?> getUsageForDay(String day) async {
    final rows = await db.query(
      'usage_daily',
      where: 'day = ?',
      whereArgs: [day],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DailyUsage.fromMap(rows.first);
  }

  /// Sum totals for a given date range (start inclusive, end exclusive)
  Future<UsageTotals> getTotalsForRange(DateTime start, DateTime end) async {
    final startDay = DayRange.formatDay(start);
    // End is exclusive. If end is midnight, last day included is day before end.
    final lastInclusiveDate = end.subtract(const Duration(milliseconds: 1));
    final endDay = DayRange.formatDay(lastInclusiveDate);

    final rows = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(mobile_rx), 0) AS mobile_rx,
        COALESCE(SUM(mobile_tx), 0) AS mobile_tx,
        COALESCE(SUM(wifi_rx), 0) AS wifi_rx,
        COALESCE(SUM(wifi_tx), 0) AS wifi_tx
      FROM usage_daily
      WHERE day >= ? AND day <= ?
    ''', [startDay, endDay]);

    if (rows.isEmpty) return const UsageTotals.zero();
    final row = rows.first;
    return UsageTotals(
      mobileRx: (row['mobile_rx'] as num?)?.toInt() ?? 0,
      mobileTx: (row['mobile_tx'] as num?)?.toInt() ?? 0,
      wifiRx: (row['wifi_rx'] as num?)?.toInt() ?? 0,
      wifiTx: (row['wifi_tx'] as num?)?.toInt() ?? 0,
    );
  }

  /// Get up to last 30 days of usage for the chart (ordered chronologically)
  Future<List<DailyUsage>> getLast30Days({DateTime? referenceNow}) async {
    final now = referenceNow ?? DateTime.now();
    final startDay = DayRange.formatDay(now.subtract(const Duration(days: 29)));
    final endDay = DayRange.formatDay(now);

    final rows = await db.query(
      'usage_daily',
      where: 'day >= ? AND day <= ?',
      whereArgs: [startDay, endDay],
      orderBy: 'day ASC',
    );

    return rows.map((r) => DailyUsage.fromMap(r)).toList();
  }
}
