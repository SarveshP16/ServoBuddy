import '../../../core/database/app_database.dart';
import '../../../core/utils/calendar.dart';

/// NSW rego renewal needs a CTP insurance "green slip" first, and cars more
/// than five years old also need a safety-check "pink slip", which can be done
/// from six weeks before the rego is due. Both hang off the rego expiry, so
/// there are no extra dates to enter.
class NswSlips {
  const NswSlips({required this.greenSlipBy, required this.pinkSlipFrom});

  /// Pink-slip inspections open this many days before rego is due.
  static const pinkSlipWindowDays = 42;

  /// Remind about the green slip this many days before rego is due, leaving
  /// time to buy it before renewing.
  static const greenSlipLeadDays = 21;

  /// Needed by rego renewal.
  final DateTime greenSlipBy;

  /// When the pink-slip window opens; null if the car doesn't need one.
  final DateTime? pinkSlipFrom;

  DateTime get greenSlipReminder => addDays(greenSlipBy, -greenSlipLeadDays);
}

/// Only the manufacture year is known, so a car counts as "over five years
/// old" from the start of its sixth calendar year. Erring early means at worst
/// an unneeded reminder, never a missed one.
bool needsPinkSlip(int manufactureYear, DateTime today) =>
    today.year - manufactureYear >= 5;

NswSlips? nswSlipsFor(Vehicle v, DateTime today) {
  final rego = v.regoExpiry;
  if (rego == null) return null;
  return NswSlips(
    greenSlipBy: rego,
    pinkSlipFrom: needsPinkSlip(v.year, today)
        ? addDays(rego, -NswSlips.pinkSlipWindowDays)
        : null,
  );
}
