import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servobuddy/features/expenses/domain/expense_category.dart';

import 'package:servobuddy/core/database/app_database.dart';
import 'package:servobuddy/core/widgets/choice_pill.dart';

import '../support/harness.dart';
import '../support/seed.dart';

void main() {
  Future<TestApp> openCorolla(WidgetTester tester) async {
    final app = await TestApp.start(tester, seed: seedMockupGarage);
    await tester.tap(find.text('TOYOTA COROLLA'));
    await app.settle(tester);
    return app;
  }

  testWidgets('vehicle detail matches the mockup', (tester) async {
    await openCorolla(tester);
    expect(find.text('2019 · Sedan · E10'), findsOneWidget);
    expect(find.text('7XY-2KL'), findsOneWidget); // On the plate.
    expect(find.text('THIS YEAR'), findsOneWidget);
    expect(find.text(r'$410'), findsOneWidget);
    expect(find.text(r'$280'), findsOneWidget);
    expect(find.text(r'$50'), findsOneWidget);
    expect(find.text('Oil change due'), findsOneWidget);
    expect(find.text('in 850 km · ~3 weeks'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Tyre rotation'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Logbook service'), findsOneWidget);
    expect(find.text('12 Jun 2026'), findsOneWidget);
    expect(find.text('02 Mar 2026'), findsOneWidget);
  });

  testWidgets('Mark done logs the service and resets the reminder', (
    tester,
  ) async {
    final app = await openCorolla(tester);
    await tester.tap(find.text('Mark done'));
    await app.settle(tester);

    expect(find.text('SERVICE RECORD'), findsOneWidget);
    // Preset to Service and to the Oil change schedule.
    final amount = find.byType(TextFormField).first;
    await tester.enterText(amount, '95');
    await tester.enterText(find.byType(TextFormField).at(1), '42,200');
    await tester.tap(find.text('Save service'));
    await app.settle(tester);

    expect(find.text('Service record saved'), findsOneWidget);
    // Next oil change is now 10,000 km on — no longer due soon.
    expect(find.text('in 850 km · ~3 weeks'), findsNothing);
    expect(find.text('Oil change due'), findsOneWidget);
    expect(find.textContaining('in 10,000 km'), findsOneWidget);

    final rows = await tester.runAsync(
      () => app.db.select(app.db.expenses).get(),
    );
    final record = rows!.firstWhere((e) => e.title == 'Oil change');
    expect(record.category, ExpenseCategory.service);
    expect(record.amountCents, 9500);
    expect(record.odometerKm, 42200);
    expect(record.scheduleId, isNotNull);
  });

  testWidgets('log a fuel fill with litres, then delete and undo', (
    tester,
  ) async {
    final app = await TestApp.start(tester, seed: seedMockupGarage);
    await tester.tap(find.text('Expenses').last);
    await app.settle(tester);
    await tester.tap(find.byTooltip('Log expense'));
    await app.settle(tester);

    expect(find.text('LOG EXPENSE'), findsOneWidget);
    // Primary car and Fuel preselected; amount required.
    await tester.tap(find.text('Save expense'));
    await tester.pump();
    expect(find.text('Enter the amount'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '73.50');
    await tester.enterText(fields.at(1), '40');
    await tester.pump();
    expect(find.text(r'Filled to full · $1.84/L'), findsOneWidget);
    await tester.tap(find.text('Save expense'));
    await app.settle(tester);

    expect(find.text('Expense saved'), findsOneWidget);
    expect(find.text(r'Today · $1.84/L · 40.0 L'), findsOneWidget);

    await tester.drag(
      find.text(r'Today · $1.84/L · 40.0 L'),
      const Offset(-500, 0),
    );
    await app.settle(tester);
    expect(find.text('Expense deleted'), findsOneWidget);
    expect(find.text(r'Today · $1.84/L · 40.0 L'), findsNothing);

    await tester.tap(find.text('Undo'));
    await app.settle(tester);
    expect(find.text(r'Today · $1.84/L · 40.0 L'), findsOneWidget);
  });

  testWidgets('expenses filter by category', (tester) async {
    final app = await TestApp.start(tester, seed: seedMockupGarage);
    await tester.tap(find.text('Expenses').last);
    await app.settle(tester);

    expect(find.text('SEPTEMBER 2026'), findsOneWidget);
    // Nine categories: the filter row scrolls sideways. Target the pill (an
    // expense row is also titled "Rego").
    final regoPill = find.byWidgetPredicate(
      (w) => w is ChoicePill && w.label == 'Rego',
    );
    await tester.ensureVisible(regoPill);
    await tester.pump();
    await tester.tap(regoPill);
    await app.settle(tester);
    // Every expense is the Corolla's, so rows don't repeat the car's name.
    expect(find.text('1 Feb 2026'), findsOneWidget); // The rego payment.
    expect(find.text('FEBRUARY 2026'), findsOneWidget);
  });

  testWidgets('expenses show all-time and yearly totals, sortable by year', (
    tester,
  ) async {
    final app = await TestApp.start(
      tester,
      seed: (db) async {
        await seedMockupGarage(db);
        await db
            .into(db.expenses)
            .insert(
              ExpensesCompanion.insert(
                vehicleId: 1,
                category: ExpenseCategory.rego,
                amountCents: 70000,
                date: DateTime(2024, 5, 10),
                title: const Value('Old rego'),
              ),
            );
      },
    );
    await tester.tap(find.text('Expenses').last);
    await app.settle(tester);

    // $740 in 2026, plus $700 in 2024.
    expect(find.text('ALL TIME'), findsOneWidget);
    expect(find.text(r'$1,440'), findsOneWidget);
    expect(find.text('THIS YEAR · 2026'), findsOneWidget);
    expect(find.text(r'$740'), findsOneWidget);
    expect(find.text('All years'), findsOneWidget);

    await tester.tap(find.text('2024'));
    await app.settle(tester);
    expect(find.text('IN 2024'), findsOneWidget);
    expect(find.text(r'$1,440'), findsOneWidget); // All time is unchanged.
    expect(find.text('MAY 2024'), findsOneWidget);
    expect(find.text('SEPTEMBER 2026'), findsNothing);

    // Totals follow the category filter.
    final fuelPill = find.byWidgetPredicate(
      (w) => w is ChoicePill && w.label == 'Fuel',
    );
    await tester.tap(fuelPill);
    await app.settle(tester);
    expect(find.text(r'$410'), findsOneWidget); // All-time fuel.
    expect(find.text(r'$0'), findsOneWidget); // No fuel in 2024.
    expect(find.text('Nothing matches these filters.'), findsOneWidget);

    await tester.tap(find.text('All years'));
    await app.settle(tester);
    expect(find.text('THIS YEAR · 2026'), findsOneWidget);
    expect(find.text('SEPTEMBER 2026'), findsOneWidget);
  });

  testWidgets('recurring costs are a second page of Expenses', (tester) async {
    final app = await TestApp.start(tester, seed: seedMockupGarage);
    await tester.tap(find.text('Expenses').last);
    await app.settle(tester);

    await tester.tap(find.text('Recurring costs'));
    await app.settle(tester);
    expect(find.text('No recurring costs'), findsOneWidget);
    await tester.tap(find.byTooltip('Add recurring cost'));
    await app.settle(tester);
    expect(find.text('RECURRING COST'), findsOneWidget);
  });

  testWidgets('add a service reminder from a preset', (tester) async {
    final app = await openCorolla(tester);
    await tester.tap(find.text('Schedule'));
    await app.settle(tester);

    expect(find.text('SERVICE SCHEDULE'), findsOneWidget);
    expect(find.text('Oil change'), findsOneWidget);
    await tester.tap(find.text('Tyre rotation'));
    await app.settle(tester);
    expect(find.text('New service reminder'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await app.settle(tester);

    expect(find.text('Every 10,000 km or 6 months'), findsOneWidget);
    // 6 months comes before the ~216 days the km would take, so the date
    // wins and is exact (no "~").
    expect(find.text('Due in 10,000 km · 6 months'), findsOneWidget);
  });
}
