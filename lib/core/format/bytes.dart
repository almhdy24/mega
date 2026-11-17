class ByteFormatter {
  ByteFormatter._();

  static String format(int bytes, {String? locale, bool isArabic = false}) {
    if (bytes < 1024) {
      final unit = isArabic ? 'بايت' : 'B';
      return '$bytes $unit';
    } else if (bytes < 1024 * 1024) {
      final kb = bytes / 1024.0;
      final unit = isArabic ? 'كيلوبايت' : 'KB';
      return '${kb.toStringAsFixed(1)} $unit';
    } else if (bytes < 1024 * 1024 * 1024) {
      final mb = bytes / (1024.0 * 1024.0);
      final unit = isArabic ? 'ميجابايت' : 'MB';
      return '${mb.toStringAsFixed(1)} $unit';
    } else {
      final gb = bytes / (1024.0 * 1024.0 * 1024.0);
      final unit = isArabic ? 'جيجابايت' : 'GB';
      return '${gb.toStringAsFixed(2)} $unit';
    }
  }

  static ({double value, String unit}) parseComponents(int bytes, {bool isArabic = false}) {
    if (bytes < 1024) {
      return (value: bytes.toDouble(), unit: isArabic ? 'بايت' : 'B');
    } else if (bytes < 1024 * 1024) {
      return (value: bytes / 1024.0, unit: isArabic ? 'كيلوبايت' : 'KB');
    } else if (bytes < 1024 * 1024 * 1024) {
      return (value: bytes / (1024.0 * 1024.0), unit: isArabic ? 'ميجابايت' : 'MB');
    } else {
      return (value: bytes / (1024.0 * 1024.0 * 1024.0), unit: isArabic ? 'جيجابايت' : 'GB');
    }
  }
}
