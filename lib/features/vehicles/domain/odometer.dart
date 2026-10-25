import '../../../core/utils/calendar.dart';

/// One known odometer value on one day, whatever it came from (a typed-in
/// reading, a fuel fill, a service).
class OdometerSample {
  const OdometerSample(this.date, this.km);

  final DateTime date;
  final int km;
}

/// The highest reading ever recorded. Odometers only go up, so the max is the
/// current value even if readings were entered out of order.
int? currentOdometer(Iterable<OdometerSample> samples) {
  int? best;
  for (final s in samples) {
    if (best == null || s.km > best) best = s.km;
  }
  return best;
}

/// Average km driven per day, from the readings of the last [windowDays]
/// days. Falls back to the whole history if that window spans less than
/// [minSpanDays] (too short to be meaningful). Null when it can't be told.
double? kmPerDay(
  Iterable<OdometerSample> samples,
  DateTime today, {
  int windowDays = 180,
  int minSpanDays = 14,
}) {
  final all = samples.toList()..sort((a, b) => a.date.compareTo(b.date));
  if (all.length < 2) return null;

  final cutoff = addDays(today, -windowDays);
  var window = all.where((s) => !s.date.isBefore(cutoff)).toList();
  if (window.length < 2 ||
      daysBetween(window.first.date, window.last.date) < minSpanDays) {
    window = all;
  }

  final days = daysBetween(window.first.date, window.last.date);
  if (days < minSpanDays) return null;
  final lowest = window.map((s) => s.km).reduce((a, b) => a < b ? a : b);
  final highest = window.map((s) => s.km).reduce((a, b) => a > b ? a : b);
  final km = highest - lowest;
  return km > 0 ? km / days : null;
}
