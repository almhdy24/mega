import 'package:flutter_test/flutter_test.dart';
import 'package:mega/core/time/billing_cycle.dart';

void main() {
  group('billingCycle', () {
    test('standard cycle mid-month', () {
      final now = DateTime(2026, 5, 15);
      final cycle = billingCycle(now, 1);
      expect(cycle.start, DateTime(2026, 5, 1));
      expect(cycle.end, DateTime(2026, 6, 1));
    });

    test('start day 31 in February non-leap year (2025)', () {
      final now = DateTime(2025, 2, 10);
      final cycle = billingCycle(now, 31);
      // In Jan, day 31 exists (Jan 31). Since now is Feb 10, start is Jan 31.
      // End month is Feb, last day of Feb 2025 is 28, clamped to 28.
      expect(cycle.start, DateTime(2025, 1, 31));
      expect(cycle.end, DateTime(2025, 2, 28));
    });

    test('start day 31 in February leap year (2024)', () {
      final now = DateTime(2024, 2, 15);
      final cycle = billingCycle(now, 31);
      expect(cycle.start, DateTime(2024, 1, 31));
      expect(cycle.end, DateTime(2024, 2, 29));
    });

    test('year rollover (Jan 5 with start day 20)', () {
      final now = DateTime(2026, 1, 5);
      final cycle = billingCycle(now, 20);
      expect(cycle.start, DateTime(2025, 12, 20));
      expect(cycle.end, DateTime(2026, 1, 20));
    });

    test('exactly on the start boundary', () {
      final now = DateTime(2026, 4, 1);
      final cycle = billingCycle(now, 1);
      expect(cycle.start, DateTime(2026, 4, 1));
      expect(cycle.end, DateTime(2026, 5, 1));
    });

    test('last day before next cycle', () {
      final now = DateTime(2026, 4, 30, 23, 59, 59);
      final cycle = billingCycle(now, 1);
      expect(cycle.start, DateTime(2026, 4, 1));
      expect(cycle.end, DateTime(2026, 5, 1));
    });
  });
}
