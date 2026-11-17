/// Current billing cycle. `end` is exclusive. startDay is clamped to month length
/// (e.g. 31 in February -> 28/29).
({DateTime start, DateTime end}) billingCycle(DateTime now, int startDay) {
  DateTime anchor(int y, int m) {
    final last = DateTime(y, m + 1, 0).day; // last day of month m
    return DateTime(y, m, startDay.clamp(1, last));
  }

  var start = anchor(now.year, now.month);
  if (start.isAfter(now)) {
    start = anchor(now.year, now.month - 1);
  }
  final end = anchor(start.year, start.month + 1);
  return (start: start, end: end);
}

/// Thresholds newly crossed and not yet notified in this cycle.
List<int> newlyCrossed({
  required int usedBytes,
  required int bundleBytes,
  required List<int> thresholds,
  required Set<int> alreadyNotified,
}) {
  if (bundleBytes <= 0) return const [];
  final pct = usedBytes * 100 / bundleBytes;
  return thresholds
      .where((t) => pct >= t && !alreadyNotified.contains(t))
      .toList()
    ..sort();
}
