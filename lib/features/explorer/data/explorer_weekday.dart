class ExplorerWeekday {
  ExplorerWeekday._();

  /// Dart [DateTime.weekday]: Monday = 1, Sunday = 7.
  static String english(DateTime dateTime) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[dateTime.weekday - 1];
  }
}
