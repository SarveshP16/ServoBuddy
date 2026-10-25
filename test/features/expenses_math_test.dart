import 'package:flutter_test/flutter_test.dart';
import 'package:servobuddy/features/expenses/domain/expense_category.dart';
import 'package:servobuddy/features/expenses/domain/fuel_economy.dart';
import 'package:servobuddy/features/expenses/domain/spend_summary.dart';

import '../support/builders.dart';

void main() {
  group('fuelStats (full-to-full)', () {
    test('first full fill only sets the baseline', () {
      final stats = fuelStats([
        expense(date: DateTime(2026, 9, 1), litres: 40, odometerKm: 1000),
      ]);
      expect(stats.litresPer100Km, isNull);
    });

    test('partial fills are added into the next full fill', () {
      final stats = fuelStats([
        expense(
          id: 1,
          date: DateTime(2026, 9, 1),
          litres: 40,
          odometerKm: 1000,
        ),
        expense(
          id: 2,
          date: DateTime(2026, 9, 5),
          litres: 10,
          fullTank: false,
          amountCents: 1700,
          odometerKm: 1200,
        ),
        expense(
          id: 3,
          date: DateTime(2026, 9, 10),
          litres: 26,
          amountCents: 4420,
          odometerKm: 1500,
        ),
      ]);
      // 36 L over 500 km.
      expect(stats.litresPer100Km, closeTo(7.2, 0.0001));
      expect(stats.centsPerKm, closeTo((1700 + 4420) / 500, 0.0001));
    });

    test('a segment with unknown litres is skipped, not guessed', () {
      final stats = fuelStats([
        expense(
          id: 1,
          date: DateTime(2026, 9, 1),
          litres: 40,
          odometerKm: 1000,
        ),
        expense(id: 2, date: DateTime(2026, 9, 5), odometerKm: 1400),
        expense(
          id: 3,
          date: DateTime(2026, 9, 9),
          litres: 30,
          odometerKm: 1800,
        ),
      ]);
      // Only 1400 → 1800 counts.
      expect(stats.litresPer100Km, closeTo(7.5, 0.0001));
    });

    test('ignores non-fuel expenses and fills without odometer', () {
      final stats = fuelStats([
        expense(
          category: ExpenseCategory.service,
          date: DateTime(2026, 9, 1),
          odometerKm: 1000,
        ),
        expense(id: 2, date: DateTime(2026, 9, 2), litres: 30),
      ]);
      expect(stats.litresPer100Km, isNull);
    });
  });

  group('spend', () {
    final expenses = [
      expense(id: 1, amountCents: 41000, date: DateTime(2026, 5, 1)),
      expense(
        id: 2,
        category: ExpenseCategory.service,
        amountCents: 18000,
        date: DateTime(2026, 6, 12),
      ),
      expense(
        id: 3,
        category: ExpenseCategory.rego,
        amountCents: 5000,
        date: DateTime(2026, 2, 1),
      ),
      expense(id: 4, amountCents: 9999, date: DateTime(2025, 12, 31)),
    ];

    test('by category for the year, matching the mockup', () {
      final by = spendByCategory(expenses, year: 2026);
      expect(by[ExpenseCategory.fuel], 41000);
      expect(by[ExpenseCategory.service], 18000);
      expect(by[ExpenseCategory.rego], 5000);
      expect(by[ExpenseCategory.insurance], 0);
      expect(totalSpend(expenses, year: 2026), 64000);
    });

    test('groups newest-first expenses by month', () {
      final sorted = [...expenses]..sort((a, b) => b.date.compareTo(a.date));
      final groups = groupByMonth(sorted);
      expect(groups.map((g) => g.month), [
        DateTime(2026, 6),
        DateTime(2026, 5),
        DateTime(2026, 2),
        DateTime(2025, 12),
      ]);
      expect(groups.first.totalCents, 18000);
    });

    test('lists years with spend, plus the current one, newest first', () {
      expect(expenseYears(expenses, current: 2027), [2027, 2026, 2025]);
      expect(expenseYears(const [], current: 2026), [2026]);
      expect(sumCents(expenses.where((e) => e.date.year == 2026)), 64000);
    });
  });
}
