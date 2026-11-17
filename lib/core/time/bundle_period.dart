import 'dart:math';

class PaceStatus {
  final bool willExceed;
  final int daysDifference;
  final DateTime estimatedExhaustionDate;
  final String statusTextAr;
  final String statusTextEn;

  const PaceStatus({
    required this.willExceed,
    required this.daysDifference,
    required this.estimatedExhaustionDate,
    required this.statusTextAr,
    required this.statusTextEn,
  });
}

class BundlePeriod {
  final DateTime start;
  final DateTime end;
  final bool isExpired;

  const BundlePeriod({
    required this.start,
    required this.end,
    required this.isExpired,
  });

  int get validityDays => max(1, end.difference(start).inDays);

  int daysLeft(DateTime now) {
    if (isExpired || now.isAfter(end)) return 0;
    final diffSec = end.difference(now).inSeconds;
    if (diffSec <= 0) return 0;
    return max(0, (diffSec / 86400).ceil());
  }

  int daysElapsed(DateTime now) {
    if (now.isBefore(start)) return 1;
    final diff = now.difference(start).inDays;
    return max(1, diff);
  }

  int safeDailyAllowance(int remainingBytes, DateTime now) {
    final left = daysLeft(now);
    if (left <= 0) return remainingBytes;
    return max(0, remainingBytes ~/ left);
  }

  PaceStatus calculatePace({
    required int usedBytes,
    required int totalBytes,
    required DateTime now,
  }) {
    final remainingBytes = max(0, totalBytes - usedBytes);
    final elapsed = daysElapsed(now);
    final dailyRate = usedBytes / elapsed;

    if (dailyRate <= 0 || usedBytes == 0) {
      return PaceStatus(
        willExceed: false,
        daysDifference: 0,
        estimatedExhaustionDate: end,
        statusTextAr: 'لم يبدأ الاستهلاك الفعلي بعد',
        statusTextEn: 'No significant usage yet',
      );
    }

    final estimatedDaysRemaining = remainingBytes / dailyRate;
    final exhaustionDate = now.add(Duration(seconds: (estimatedDaysRemaining * 86400).round()));

    if (exhaustionDate.isBefore(end)) {
      final daysEarly = max(1, end.difference(exhaustionDate).inDays);
      return PaceStatus(
        willExceed: true,
        daysDifference: daysEarly,
        estimatedExhaustionDate: exhaustionDate,
        statusTextAr: 'ستنتهي قبل الموعد بـ $daysEarly أيام',
        statusTextEn: 'Will run out $daysEarly days early',
      );
    } else {
      final formattedDay = '${end.day}/${end.month}';
      return PaceStatus(
        willExceed: false,
        daysDifference: 0,
        estimatedExhaustionDate: exhaustionDate,
        statusTextAr: 'على المعدل الحالي تكفيك حتى $formattedDay',
        statusTextEn: 'At current rate, lasts until $formattedDay',
      );
    }
  }

  static BundlePeriod compute({
    required int startMs,
    required int validityDays,
    required bool autoRenew,
    required DateTime now,
  }) {
    final validDays = max(1, validityDays);
    final validityDuration = Duration(days: validDays);

    if (startMs <= 0) {
      return BundlePeriod(
        start: now,
        end: now.add(validityDuration),
        isExpired: false,
      );
    }

    var periodStart = DateTime.fromMillisecondsSinceEpoch(startMs);
    var periodEnd = periodStart.add(validityDuration);

    if (autoRenew) {
      while (now.isAfter(periodEnd) || now.isAtSameMomentAs(periodEnd)) {
        periodStart = periodEnd;
        periodEnd = periodStart.add(validityDuration);
      }
      return BundlePeriod(start: periodStart, end: periodEnd, isExpired: false);
    } else {
      final expired = now.isAfter(periodEnd);
      return BundlePeriod(start: periodStart, end: periodEnd, isExpired: expired);
    }
  }
}
