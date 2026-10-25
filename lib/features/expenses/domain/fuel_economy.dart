import '../../../core/database/app_database.dart';
import 'expense_category.dart';

class FuelStats {
  const FuelStats({required this.litresPer100Km, required this.centsPerKm});

  static const none = FuelStats(litresPer100Km: null, centsPerKm: null);

  final double? litresPer100Km;
  final double? centsPerKm;
}

/// Fuel economy by the full-to-full method: the fuel put in at a full fill
/// (plus any partial fills since the previous full fill) is what was burned
/// over the km since that previous full fill. A segment with a missing
/// litres figure is skipped rather than guessed.
FuelStats fuelStats(Iterable<Expense> expenses) {
  final fills =
      expenses
          .where(
            (e) => e.category == ExpenseCategory.fuel && e.odometerKm != null,
          )
          .toList()
        ..sort((a, b) {
          final byKm = a.odometerKm!.compareTo(b.odometerKm!);
          return byKm != 0 ? byKm : a.date.compareTo(b.date);
        });

  var litres = 0.0;
  var cents = 0;
  var km = 0;

  int? lastFullKm;
  var segLitres = 0.0;
  var segCents = 0;
  var segComplete = true;
  for (final f in fills) {
    if (lastFullKm == null) {
      if (f.fullTank) lastFullKm = f.odometerKm;
      continue;
    }
    if (f.litres == null) segComplete = false;
    segLitres += f.litres ?? 0;
    segCents += f.amountCents;
    if (f.fullTank) {
      final distance = f.odometerKm! - lastFullKm;
      if (segComplete && distance > 0 && segLitres > 0) {
        litres += segLitres;
        cents += segCents;
        km += distance;
      }
      lastFullKm = f.odometerKm;
      segLitres = 0;
      segCents = 0;
      segComplete = true;
    }
  }

  if (km == 0) return FuelStats.none;
  return FuelStats(litresPer100Km: litres / km * 100, centsPerKm: cents / km);
}
