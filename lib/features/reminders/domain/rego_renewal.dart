import '../../../core/database/app_database.dart';
import '../../../core/utils/calendar.dart';
import '../../expenses/domain/expense_category.dart';
import 'nsw_slips.dart';

/// The steps of an NSW rego renewal, in the order they have to happen. Each
/// is ticked off by logging a Rego expense with its title.
enum RenewalStep {
  greenSlip('CTP green slip'),
  pinkSlip('Pink slip inspection'),
  payRego('Rego renewal');

  const RenewalStep(this.title);

  /// Also the expense title that marks it done.
  final String title;
}

/// Where one car's rego renewal stands, once it's close enough to matter.
class RegoRenewal {
  const RegoRenewal({required this.expiry, required this.steps});

  /// Shown from when pink-slip checks open: six weeks out.
  static const showFromDays = NswSlips.pinkSlipWindowDays;

  /// An expense counts towards this renewal if it's no older than this
  /// before the expiry. Last year's green slip is well outside it.
  static const _lookBackDays = 90;

  final DateTime expiry;

  /// Each step and the expense that ticked it off, if any.
  final List<({RenewalStep step, Expense? done})> steps;

  int get doneCount => steps.where((s) => s.done != null).length;
}

/// The checklist for [v], or null when rego isn't due within six weeks (or
/// the car is out of use, or has no rego date).
RegoRenewal? regoRenewalFor(
  Vehicle v,
  List<Expense> vehicleExpenses,
  DateTime today,
) {
  final expiry = v.regoExpiry;
  if (expiry == null) return null;
  if (daysBetween(today, expiry) > RegoRenewal.showFromDays) return null;

  final since = addDays(expiry, -RegoRenewal._lookBackDays);
  Expense? doneBy(RenewalStep step) {
    for (final e in vehicleExpenses) {
      if (e.category == ExpenseCategory.rego &&
          e.title?.trim().toLowerCase() == step.title.toLowerCase() &&
          !e.date.isBefore(since)) {
        return e;
      }
    }
    return null;
  }

  return RegoRenewal(
    expiry: expiry,
    steps: [
      for (final step in RenewalStep.values)
        if (step != RenewalStep.pinkSlip || needsPinkSlip(v.year, today))
          (step: step, done: doneBy(step)),
    ],
  );
}
