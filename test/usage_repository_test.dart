import 'package:flutter_test/flutter_test.dart';
import 'package:mega/core/db/migrations.dart';
import 'package:mega/core/platform/usage_channel.dart';
import 'package:mega/core/time/day_range.dart';
import 'package:mega/features/usage/data/usage_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockUsageSource implements UsageSource {
  bool accessGranted = true;
  final Map<String, UsageTotals> dayData = {};

  @override
  Future<bool> hasAccess() async => accessGranted;

  @override
  Future<void> openAccessSettings() async {}

  @override
  Future<void> scheduleAlertWorker() async {}

  @override
  Future<void> cancelAlertWorker() async {}

  @override
  Future<UsageTotals> queryRange(DateTime startLocal, DateTime endLocal) async {
    final dayKey = DayRange.formatDay(startLocal);
    return dayData[dayKey] ?? const UsageTotals.zero();
  }
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late MockUsageSource mockSource;
  late UsageRepository repository;

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    for (final migration in migrations) {
      await migration(db);
    }
    mockSource = MockUsageSource();
    repository = UsageRepository(db: db, usageSource: mockSource);
  });

  tearDown(() async {
    await db.close();
  });

  group('UsageRepository & Snapshot MAX rule', () {
    test('syncSnapshots persists data correctly', () async {
      final now = DateTime(2026, 5, 20);
      final dayKey = DayRange.formatDay(now);

      mockSource.dayData[dayKey] = const UsageTotals(
        mobileRx: 1000,
        mobileTx: 500,
        wifiRx: 2000,
        wifiTx: 1000,
      );

      await repository.syncSnapshots(days: 1, referenceNow: now);

      final row = await repository.getUsageForDay(dayKey);
      expect(row, isNotNull);
      expect(row!.mobileRx, 1000);
      expect(row.mobileTx, 500);
      expect(row.wifiRx, 2000);
      expect(row.wifiTx, 1000);
      expect(row.mobileTotal, 1500);
      expect(row.wifiTotal, 3000);
    });

    test('MAX rule: expired history returning 0 does NOT overwrite existing non-zero stored value', () async {
      final now = DateTime(2026, 5, 20);
      final dayKey = DayRange.formatDay(now);

      // Initial query: 50 MB mobile rx
      mockSource.dayData[dayKey] = const UsageTotals(
        mobileRx: 50000000,
        mobileTx: 10000000,
        wifiRx: 20000000,
        wifiTx: 5000000,
      );
      await repository.syncSnapshots(days: 1, referenceNow: now);

      // Simulate Android expiring history for this day: queryRange returns 0
      mockSource.dayData[dayKey] = const UsageTotals.zero();
      await repository.syncSnapshots(days: 1, referenceNow: now);

      // Verify stored row preserved the MAX non-zero value
      final row = await repository.getUsageForDay(dayKey);
      expect(row, isNotNull);
      expect(row!.mobileRx, 50000000);
      expect(row.mobileTx, 10000000);
      expect(row.wifiRx, 20000000);
      expect(row.wifiTx, 5000000);
    });

    test('MAX rule: higher new value replaces existing lower value', () async {
      final now = DateTime(2026, 5, 20);
      final dayKey = DayRange.formatDay(now);

      mockSource.dayData[dayKey] = const UsageTotals(
        mobileRx: 100,
        mobileTx: 50,
        wifiRx: 200,
        wifiTx: 100,
      );
      await repository.syncSnapshots(days: 1, referenceNow: now);

      // Updated later in the day: more data used
      mockSource.dayData[dayKey] = const UsageTotals(
        mobileRx: 300,
        mobileTx: 50,
        wifiRx: 200,
        wifiTx: 400,
      );
      await repository.syncSnapshots(days: 1, referenceNow: now);

      final row = await repository.getUsageForDay(dayKey);
      expect(row!.mobileRx, 300);
      expect(row.mobileTx, 50);
      expect(row.wifiRx, 200);
      expect(row.wifiTx, 400);
    });

    test('getTotalsForRange sums multiple days accurately', () async {
      final day1 = DateTime(2026, 5, 1);
      final day2 = DateTime(2026, 5, 2);

      mockSource.dayData[DayRange.formatDay(day1)] = const UsageTotals(
        mobileRx: 100,
        mobileTx: 100,
        wifiRx: 500,
        wifiTx: 500,
      );
      mockSource.dayData[DayRange.formatDay(day2)] = const UsageTotals(
        mobileRx: 200,
        mobileTx: 300,
        wifiRx: 1000,
        wifiTx: 1000,
      );

      await repository.syncSnapshots(days: 2, referenceNow: day2);

      final totals = await repository.getTotalsForRange(day1, DateTime(2026, 5, 3));
      expect(totals.mobileRx, 300);
      expect(totals.mobileTx, 400);
      expect(totals.wifiRx, 1500);
      expect(totals.wifiTx, 1500);
      expect(totals.mobileTotal, 700);
      expect(totals.wifiTotal, 3000);
    });
    test('handles mobileSupported = false on unsupported Android versions', () async {
      const unsupported = UsageTotals(
        mobileRx: 0,
        mobileTx: 0,
        wifiRx: 500,
        wifiTx: 300,
        mobileSupported: false,
      );

      expect(unsupported.mobileSupported, isFalse);
      expect(unsupported.mobileTotal, 0);
      expect(unsupported.wifiTotal, 800);
      expect(unsupported.grandTotal, 800);

      final combined = unsupported + const UsageTotals(
        mobileRx: 10,
        mobileTx: 10,
        wifiRx: 10,
        wifiTx: 10,
        mobileSupported: true,
      );
      // Combined should preserve unsupported state
      expect(combined.mobileSupported, isFalse);
    });
  });
}
