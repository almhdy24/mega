import 'package:flutter_test/flutter_test.dart';
import 'package:mega/core/time/billing_cycle.dart';

void main() {
  group('newlyCrossed alerts', () {
    const thresholds = [50, 80, 100];
    const bundle = 1000; // e.g. 1000 MB

    test('returns empty when bundleBytes is 0 or negative', () {
      expect(
        newlyCrossed(
          usedBytes: 500,
          bundleBytes: 0,
          thresholds: thresholds,
          alreadyNotified: {},
        ),
        isEmpty,
      );
      expect(
        newlyCrossed(
          usedBytes: 500,
          bundleBytes: -100,
          thresholds: thresholds,
          alreadyNotified: {},
        ),
        isEmpty,
      );
    });

    test('triggers 50% when used reaches 500/1000', () {
      final crossed = newlyCrossed(
        usedBytes: 500,
        bundleBytes: bundle,
        thresholds: thresholds,
        alreadyNotified: {},
      );
      expect(crossed, equals([50]));
    });

    test('ignores thresholds already notified', () {
      final crossed = newlyCrossed(
        usedBytes: 550,
        bundleBytes: bundle,
        thresholds: thresholds,
        alreadyNotified: {50},
      );
      expect(crossed, isEmpty);
    });

    test('triggers 80% when jumping from 50% to 80%', () {
      final crossed = newlyCrossed(
        usedBytes: 800,
        bundleBytes: bundle,
        thresholds: thresholds,
        alreadyNotified: {50},
      );
      expect(crossed, equals([80]));
    });

    test('triggers multiple thresholds at once if usage jumped across them', () {
      final crossed = newlyCrossed(
        usedBytes: 1000,
        bundleBytes: bundle,
        thresholds: thresholds,
        alreadyNotified: {},
      );
      expect(crossed, equals([50, 80, 100]));
    });

    test('returns empty when all thresholds have fired', () {
      final crossed = newlyCrossed(
        usedBytes: 1200,
        bundleBytes: bundle,
        thresholds: thresholds,
        alreadyNotified: {50, 80, 100},
      );
      expect(crossed, isEmpty);
    });
  });
}
