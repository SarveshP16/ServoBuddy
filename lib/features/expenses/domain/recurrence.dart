import '../../../core/utils/calendar.dart';

enum RecurFrequency {
  weekly('Weekly', 'week', 52),
  fortnightly('Fortnightly', 'fortnight', 26),
  monthly('Monthly', 'month', 12),
  quarterly('Quarterly', 'quarter', 4),
  yearly('Yearly', 'year', 1);

  const RecurFrequency(this.label, this.unit, this.perYear);

  final String label;

  /// "$120 a month".
  final String unit;

  /// How many times it comes around in a year.
  final int perYear;
}

/// The [n]th due date (0 = the first) of something repeating from [start].
///
/// Always counted from the start rather than from the previous date, so a
/// monthly cost on the 31st lands on 28/30/31 as each month allows and then
/// returns to the 31st, instead of drifting to the 28th for good.
DateTime occurrence(DateTime start, RecurFrequency f, int n) => switch (f) {
  RecurFrequency.weekly => addDays(start, 7 * n),
  RecurFrequency.fortnightly => addDays(start, 14 * n),
  RecurFrequency.monthly => addMonths(start, n),
  RecurFrequency.quarterly => addMonths(start, 3 * n),
  RecurFrequency.yearly => addMonths(start, 12 * n),
};

/// Due dates from [handled] onwards that have arrived by [today], oldest
/// first. These wait for you to log or skip them.
List<DateTime> pendingOccurrences({
  required DateTime start,
  required RecurFrequency frequency,
  required int handled,
  required DateTime today,
}) {
  final day = dateOnly(today);
  final out = <DateTime>[];
  for (var n = handled; ; n++) {
    final due = occurrence(start, frequency, n);
    if (due.isAfter(day)) return out;
    out.add(due);
  }
}
