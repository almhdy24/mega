import 'speed_server.dart';

/// Calculates the median of a list of RTT values (in milliseconds).
double medianMs(List<double> rtts) {
  if (rtts.isEmpty) return 0.0;
  final sorted = List<double>.from(rtts)..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length % 2 == 1) {
    return sorted[mid];
  } else {
    return (sorted[mid - 1] + sorted[mid]) / 2.0;
  }
}

/// Calculates jitter (RFC 3550 / mean consecutive difference) of RTT values.
double jitterMs(List<double> rtts) {
  if (rtts.length < 2) return 0.0;
  double sumDiff = 0.0;
  for (var i = 1; i < rtts.length; i++) {
    sumDiff += (rtts[i] - rtts[i - 1]).abs();
  }
  return sumDiff / (rtts.length - 1);
}

/// Classifies network jitter stability.
SpeedStability stabilityRating(double jitter) {
  if (jitter <= 0) return SpeedStability.excellent;
  if (jitter < 15.0) return SpeedStability.excellent;
  if (jitter <= 50.0) return SpeedStability.good;
  return SpeedStability.unstable;
}

/// Returns estimated data usage range string for chosen mode.
String estimateDataUsage(SpeedTestMode mode, bool isArabic) {
  switch (mode) {
    case SpeedTestMode.quick:
      return isArabic ? '3–8 ميجابايت' : '3–8 MB';
    case SpeedTestMode.full:
      return isArabic ? '15–25 ميجابايت' : '15–25 MB';
  }
}

/// Calculates speed in Mbps given transferred bytes and duration.
double mbps(int bytes, Duration d) {
  final seconds = d.inMicroseconds / 1e6;
  if (seconds <= 0 || bytes <= 0) return 0.0;
  return (bytes * 8.0) / seconds / 1e6;
}

/// Computes trimmed mean of samples, discarding top and bottom [trim] fraction.
/// Default trim is 0.1 (10% top and 10% bottom).
double trimmedMean(List<double> samples, {double trim = 0.1}) {
  if (samples.isEmpty) return 0.0;
  if (samples.length == 1) return samples.first;

  final sorted = List<double>.from(samples)..sort();
  final dropCount = (sorted.length * trim).floor();

  final validStart = dropCount;
  final validEnd = sorted.length - dropCount;

  if (validStart >= validEnd) {
    // If dropCount removed everything, return median
    return medianMs(sorted);
  }

  final trimmed = sorted.sublist(validStart, validEnd);
  final sum = trimmed.reduce((a, b) => a + b);
  return sum / trimmed.length;
}
