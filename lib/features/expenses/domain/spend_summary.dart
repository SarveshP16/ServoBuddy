import '../../../core/database/app_database.dart';
import 'expense_category.dart';

/// Total spent per category in calendar [year], in cents. Every category is
/// present (zero if nothing was spent) so callers can order them freely.
Map<ExpenseCategory, int> spendByCategory(
  Iterable<Expense> expenses, {
  required int year,
}) {
  final totals = {for (final c in ExpenseCategory.values) c: 0};
  for (final e in expenses) {
    if (e.date.year == year) {
      totals[e.category] = totals[e.category]! + e.amountCents;
    }
  }
  return totals;
}

int totalSpend(Iterable<Expense> expenses, {required int year}) =>
    sumCents(expenses.where((e) => e.date.year == year));

int sumCents(Iterable<Expense> expenses) =>
    expenses.fold(0, (sum, e) => sum + e.amountCents);

/// Every calendar year with an expense, plus [current], newest first.
List<int> expenseYears(Iterable<Expense> expenses, {required int current}) =>
    {current, for (final e in expenses) e.date.year}.toList()
      ..sort((a, b) => b.compareTo(a));

typedef MonthGroup = ({DateTime month, List<Expense> items, int totalCents});

/// Groups expenses (already sorted newest first) by calendar month, keeping
/// their order.
List<MonthGroup> groupByMonth(List<Expense> expenses) {
  final groups = <MonthGroup>[];
  for (final e in expenses) {
    final month = DateTime(e.date.year, e.date.month);
    if (groups.isEmpty || groups.last.month != month) {
      groups.add((month: month, items: [e], totalCents: e.amountCents));
    } else {
      final last = groups.removeLast();
      groups.add((
        month: month,
        items: [...last.items, e],
        totalCents: last.totalCents + e.amountCents,
      ));
    }
  }
  return groups;
}
