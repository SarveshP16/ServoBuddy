import '../../../core/database/app_database.dart';
import '../../../core/utils/calendar.dart';
import '../../expenses/domain/expense_category.dart';
import '../../garage/domain/garage.dart';
import 'wash_type.dart';

/// One line of a car's wash history: a logged wash, or a Car wash expense
/// that has no wash behind it (logged in Expenses, or from before washes were
/// tracked).
class WashEntry {
  const WashEntry({
    required this.date,
    required this.title,
    required this.amountCents,
    this.type,
    this.place,
    this.wash,
    this.expense,
  });

  final DateTime date;

  /// Null for an expense-only entry: how it was washed isn't known.
  final WashType? type;
  final String title;
  final String? place;
  final int amountCents;
  final Wash? wash;
  final Expense? expense;
}

/// Newest first.
List<WashEntry> washHistory(Garage garage, int vehicleId) {
  final washes = garage.washesFor(vehicleId);
  final linked = {for (final w in washes) ?w.expenseId};
  return [
    for (final w in washes)
      WashEntry(
        date: w.date,
        type: w.type,
        title: w.type.title,
        place: w.place,
        amountCents: w.amountCents,
        wash: w,
      ),
    for (final e in garage.expensesFor(vehicleId))
      if (e.category == ExpenseCategory.carWash && !linked.contains(e.id))
        WashEntry(
          date: e.date,
          title: e.title ?? 'Car wash',
          place: e.notes,
          amountCents: e.amountCents,
          expense: e,
        ),
  ]..sort((a, b) => b.date.compareTo(a.date));
}

class WashStats {
  const WashStats({
    required this.last,
    required this.countThisYear,
    required this.spendThisYear,
    required this.averageGapDays,
    required this.byType,
  });

  final WashEntry? last;
  final int countThisYear;
  final int spendThisYear;

  /// Average days between washes over the last year; null with fewer than
  /// two.
  final int? averageGapDays;

  /// How many of each type this year (expense-only washes are left out).
  final Map<WashType, int> byType;
}

WashStats washStats(List<WashEntry> history, DateTime today) {
  final thisYear = [
    for (final e in history)
      if (e.date.year == today.year) e,
  ];
  final yearAgo = addDays(today, -365);
  final recent = [
    for (final e in history)
      if (!e.date.isBefore(yearAgo)) e,
  ];
  return WashStats(
    last: history.firstOrNull,
    countThisYear: thisYear.length,
    spendThisYear: thisYear.fold(0, (sum, e) => sum + e.amountCents),
    averageGapDays: recent.length < 2
        ? null
        : (daysBetween(recent.last.date, recent.first.date) /
                  (recent.length - 1))
              .round(),
    byType: {
      for (final t in WashType.values)
        if (thisYear.where((e) => e.type == t).length case final n when n > 0)
          t: n,
    },
  );
}

/// Places washed at before, most recent first, each with what it cost last
/// time, for one-tap filling of the paid-wash form.
List<({String place, WashType type, int amountCents})> rememberedPlaces(
  Garage garage, {
  int max = 4,
}) {
  final seen = <String>{};
  final out = <({String place, WashType type, int amountCents})>[];
  for (final w in garage.washes) {
    final place = w.place?.trim();
    if (place == null || place.isEmpty || !w.type.paid) continue;
    if (!seen.add(place.toLowerCase())) continue;
    out.add((place: place, type: w.type, amountCents: w.amountCents));
    if (out.length == max) break;
  }
  return out;
}

/// When the next wash is due, if the car has a wash reminder set: that many
/// days after the last wash (or from today if it's never been washed).
DateTime? nextWashDue(Vehicle v, List<WashEntry> history, DateTime today) {
  final every = v.washEveryDays;
  if (every == null) return null;
  return addDays(history.firstOrNull?.date ?? today, every);
}
