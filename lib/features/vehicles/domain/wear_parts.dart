import '../../../core/database/app_database.dart';
import '../../../core/utils/calendar.dart';

/// Parts that wear out on a clock of their own, outside the service schedule.
enum WearPart {
  /// About five years whatever the tread says (the rubber hardens), or
  /// sooner by distance.
  tyres('Tyres', lifeMonths: 60, lifeKm: 40000),

  /// Most car batteries last three to five years; four is the middle.
  battery('Battery', lifeMonths: 48);

  const WearPart(this.label, {required this.lifeMonths, this.lifeKm});

  /// Also the expense title that records a new one being fitted.
  final String label;
  final int lifeMonths;
  final int? lifeKm;
}

enum WearStatus { ok, soon, due }

/// How old a part is and when to replace it.
class PartAge {
  const PartAge({
    required this.part,
    required this.fitted,
    required this.replaceBy,
    required this.replaceAtKm,
    required this.status,
    required this.ageDays,
  });

  /// Flagged as "soon" this close to either limit.
  static const soonDays = 90;
  static const soonKm = 3000;

  final WearPart part;
  final DateTime fitted;

  /// The earlier of its age limit and, for tyres, when the distance limit
  /// should be reached at the current pace.
  final DateTime replaceBy;

  /// Tyres only, when the odometer at fitting is known.
  final int? replaceAtKm;
  final WearStatus status;
  final int ageDays;
}

DateTime? fittedDate(Vehicle v, WearPart part) => switch (part) {
  WearPart.tyres => v.tyresFitted,
  WearPart.battery => v.batteryFitted,
};

/// Null until a fitting date is recorded.
PartAge? partAgeFor(
  Vehicle v,
  WearPart part, {
  required DateTime today,
  int? currentKm,
  double? kmPerDay,
}) {
  final fitted = fittedDate(v, part);
  if (fitted == null) return null;

  var replaceBy = addMonths(fitted, part.lifeMonths);
  int? replaceAtKm;
  int? kmLeft;
  final fittedKm = part == WearPart.tyres ? v.tyresFittedKm : null;
  if (part.lifeKm != null && fittedKm != null) {
    replaceAtKm = fittedKm + part.lifeKm!;
    if (currentKm != null) {
      kmLeft = replaceAtKm - currentKm;
      if (kmPerDay != null && kmPerDay > 0) {
        final byKm = addDays(today, (kmLeft / kmPerDay).floor());
        if (byKm.isBefore(replaceBy)) replaceBy = byKm;
      }
    }
  }

  final daysLeft = daysBetween(today, replaceBy);
  final status = daysLeft <= 0 || (kmLeft != null && kmLeft <= 0)
      ? WearStatus.due
      : daysLeft <= PartAge.soonDays ||
            (kmLeft != null && kmLeft <= PartAge.soonKm)
      ? WearStatus.soon
      : WearStatus.ok;
  return PartAge(
    part: part,
    fitted: fitted,
    replaceBy: replaceBy,
    replaceAtKm: replaceAtKm,
    status: status,
    ageDays: daysBetween(fitted, today),
  );
}

/// "2 yrs 7 mths", "5 mths", "3 weeks".
String formatAge(DateTime from, DateTime today) {
  var months = (today.year - from.year) * 12 + today.month - from.month;
  if (today.day < from.day) months--;
  if (months < 1) {
    final days = daysBetween(from, today);
    return days < 14
        ? '$days ${days == 1 ? 'day' : 'days'}'
        : '${days ~/ 7} weeks';
  }
  final years = months ~/ 12;
  final rest = months % 12;
  String unit(int n, String one, String many) => '$n ${n == 1 ? one : many}';
  return [
    if (years > 0) unit(years, 'yr', 'yrs'),
    if (rest > 0) unit(rest, 'mth', 'mths'),
  ].join(' ');
}
