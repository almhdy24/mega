import 'package:flutter_test/flutter_test.dart';
import 'package:mega/core/time/bundle_period.dart';

void main() {
  group('BundlePeriod & Math', () {
    test('compute: fresh bundle within validity', () {
      final start = DateTime(2026, 6, 1, 10, 0, 0);
      final now = DateTime(2026, 6, 5, 10, 0, 0);
      final period = BundlePeriod.compute(
        startMs: start.millisecondsSinceEpoch,
        validityDays: 30,
        autoRenew: false,
        now: now,
      );

      expect(period.start, start);
      expect(period.end, start.add(const Duration(days: 30)));
      expect(period.isExpired, false);
      expect(period.daysLeft(now), 26);
      expect(period.daysElapsed(now), 4);
    });

    test('compute: expired bundle with autoRenew = false', () {
      final start = DateTime(2026, 6, 1, 10, 0, 0);
      final now = DateTime(2026, 7, 5, 10, 0, 0); // 34 days later
      final period = BundlePeriod.compute(
        startMs: start.millisecondsSinceEpoch,
        validityDays: 30,
        autoRenew: false,
        now: now,
      );

      expect(period.isExpired, true);
      expect(period.daysLeft(now), 0);
    });

    test('compute: expired bundle with autoRenew = true advances periods', () {
      final start = DateTime(2026, 6, 1, 10, 0, 0);
      final now = DateTime(2026, 7, 5, 10, 0, 0); // 34 days later
      final period = BundlePeriod.compute(
        startMs: start.millisecondsSinceEpoch,
        validityDays: 30,
        autoRenew: true,
        now: now,
      );

      // Advanced by 1 period (30 days)
      expect(period.isExpired, false);
      expect(period.start, start.add(const Duration(days: 30)));
      expect(period.end, start.add(const Duration(days: 60)));
      expect(period.daysLeft(now), 26);
    });

    test('safeDailyAllowance: calculates remaining / days left', () {
      final start = DateTime(2026, 6, 1, 0, 0, 0);
      final now = DateTime(2026, 6, 21, 0, 0, 0); // 10 days left
      final period = BundlePeriod.compute(
        startMs: start.millisecondsSinceEpoch,
        validityDays: 30,
        autoRenew: false,
        now: now,
      );

      final allowance = period.safeDailyAllowance(10000000000, now); // 10 GB remaining
      expect(allowance, 1000000000); // 1 GB / day
    });

    test('calculatePace: warns when bundle runs out early', () {
      final start = DateTime(2026, 6, 1, 0, 0, 0);
      final now = DateTime(2026, 6, 11, 0, 0, 0); // 10 days elapsed, 20 days left
      final period = BundlePeriod.compute(
        startMs: start.millisecondsSinceEpoch,
        validityDays: 30,
        autoRenew: false,
        now: now,
      );

      // Used 80 GB of 100 GB in 10 days (rate: 8 GB/day). Remaining 20 GB will last 2.5 days!
      const totalBytes = 100 * 1024 * 1024 * 1024;
      const usedBytes = 80 * 1024 * 1024 * 1024;

      final pace = period.calculatePace(
        usedBytes: usedBytes,
        totalBytes: totalBytes,
        now: now,
      );

      expect(pace.willExceed, true);
      expect(pace.daysDifference, greaterThan(15));
      expect(pace.statusTextAr, contains('ستنتهي قبل الموعد'));
    });

    test('calculatePace: confirms when bundle pace is safe', () {
      final start = DateTime(2026, 6, 1, 0, 0, 0);
      final now = DateTime(2026, 6, 11, 0, 0, 0); // 10 days elapsed, 20 days left
      final period = BundlePeriod.compute(
        startMs: start.millisecondsSinceEpoch,
        validityDays: 30,
        autoRenew: false,
        now: now,
      );

      // Used 10 GB of 100 GB in 10 days (rate: 1 GB/day). Remaining 90 GB will easily last 20 days.
      const totalBytes = 100 * 1024 * 1024 * 1024;
      const usedBytes = 10 * 1024 * 1024 * 1024;

      final pace = period.calculatePace(
        usedBytes: usedBytes,
        totalBytes: totalBytes,
        now: now,
      );

      expect(pace.willExceed, false);
      expect(pace.statusTextAr, contains('على المعدل الحالي تكفيك'));
    });
  });
}
