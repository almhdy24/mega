import 'package:flutter_test/flutter_test.dart';
import 'package:mega/features/speedtest/domain/speed_math.dart';

void main() {
  group('Speed Math Functions', () {
    test('medianMs handles empty, odd, and even lists', () {
      expect(medianMs([]), 0.0);
      expect(medianMs([42.0]), 42.0);
      expect(medianMs([10.0, 50.0, 20.0]), 20.0);
      expect(medianMs([10.0, 20.0, 30.0, 40.0]), 25.0);
    });

    test('jitterMs calculates mean consecutive absolute differences', () {
      expect(jitterMs([]), 0.0);
      expect(jitterMs([10.0]), 0.0);
      // diffs: |20 - 10| = 10, |15 - 20| = 5 -> mean = 15 / 2 = 7.5
      expect(jitterMs([10.0, 20.0, 15.0]), 7.5);
      // steady ping: diffs are 0
      expect(jitterMs([20.0, 20.0, 20.0]), 0.0);
    });

    test('mbps calculates bit rate accurately', () {
      expect(mbps(0, const Duration(seconds: 1)), 0.0);
      expect(mbps(1000, Duration.zero), 0.0);
      // 1 Megabyte (1,000,000 bytes) in 1 second = 8 Mbps
      expect(mbps(1000000, const Duration(seconds: 1)), 8.0);
      // 12.5 Megabytes in 1 second = 100 Mbps
      expect(mbps(12500000, const Duration(seconds: 1)), 100.0);
      // 5 Megabytes in 500 ms = 80 Mbps
      expect(mbps(5000000, const Duration(milliseconds: 500)), 80.0);
    });

    test('trimmedMean drops top and bottom 10%', () {
      expect(trimmedMean([]), 0.0);
      expect(trimmedMean([50.0]), 50.0);

      // 10 samples from 10 to 100 (sorted: 10, 20, 30, 40, 50, 60, 70, 80, 90, 100)
      // 10% trim = drop lowest 1 (10) and highest 1 (100)
      // Remaining: 20, 30, 40, 50, 60, 70, 80, 90 -> sum = 440 / 8 = 55.0
      final samples = [100.0, 10.0, 50.0, 20.0, 80.0, 30.0, 70.0, 40.0, 90.0, 60.0];
      expect(trimmedMean(samples, trim: 0.1), 55.0);
    });
  });
}
