class SpeedFormatter {
  SpeedFormatter._();

  static String formatMbps(double mbps, {bool isArabic = false}) {
    final unit = isArabic ? 'ميجابت/ث' : 'Mbps';
    if (mbps < 0.1 && mbps > 0) {
      return '<0.1 $unit';
    }
    return '${mbps.toStringAsFixed(1)} $unit';
  }

  static String formatMs(double ms, {bool isArabic = false}) {
    final unit = isArabic ? 'ملي ثانية' : 'ms';
    return '${ms.round()} $unit';
  }
}
