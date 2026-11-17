class DayRange {
  DayRange._();

  /// Returns local midnight of the given date.
  static DateTime startOfDay(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  /// Returns local midnight of the next day (exclusive end).
  static DateTime endOfDay(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day + 1);
  }

  /// Formats date to 'YYYY-MM-DD'.
  static String formatDay(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Parses 'YYYY-MM-DD' into local DateTime.
  static DateTime parseDay(String dayStr) {
    final parts = dayStr.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
