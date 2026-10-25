/// Calendar arithmetic on local dates.
///
/// Never use `date.add(Duration(days: n))` for day maths: on a local DateTime
/// that follows wall-clock hours, so it lands an hour off midnight whenever
/// the span crosses a daylight-saving change (NSW has two a year). Building a
/// new DateTime from calendar fields lets Dart normalise it exactly.
library;

/// Midnight at the start of [d]'s day.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

/// Same day [months] later, clamped to the end of shorter months
/// (31 Jan + 1 month = 28/29 Feb, not 2/3 Mar).
DateTime addMonths(DateTime d, int months) {
  final firstOfTarget = DateTime(d.year, d.month + months);
  final lastDay = DateTime(firstOfTarget.year, firstOfTarget.month + 1, 0).day;
  return DateTime(
    firstOfTarget.year,
    firstOfTarget.month,
    d.day > lastDay ? lastDay : d.day,
  );
}

/// Whole calendar days from [from] to [to] (negative if [to] is earlier).
/// Counted in UTC so a DST change in between can't shave off an hour.
int daysBetween(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}
