import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servobuddy/core/database/app_database.dart';
import 'package:servobuddy/features/expenses/domain/expense_category.dart';
import 'package:servobuddy/features/expenses/domain/recurrence.dart';

import '../support/harness.dart';
import '../support/seed.dart';

/// Monthly car insurance on the Corolla, first due 1 Aug — so on the test's
/// "today" (23 Sep) the 1 Aug and 1 Sep payments are waiting.
Future<void> seedWithInsurance(AppDatabase db) async {
  await seedMockupGarage(db);
  await db
      .into(db.recurringExpenses)
      .insert(
        RecurringExpensesCompanion.insert(
          vehicleId: 1,
          category: ExpenseCategory.insurance,
          amountCents: 12000,
          title: const Value('Car insurance'),
          frequency: RecurFrequency.monthly,
          startDate: DateTime(2026, 8, 1),
        ),
      );
}

void main() {
  group('recurring costs', () {
    testWidgets('due payments wait on Home until you log them', (tester) async {
      final app = await TestApp.start(tester, seed: seedWithInsurance);
      // Three cars in the garage, so the card names the car.
      expect(find.text('Car insurance — Corolla'), findsOneWidget);
      expect(
        find.text('Due 1 Aug 2026 · Monthly · 1 more waiting'),
        findsOneWidget,
      );

      await tester.tap(find.text(r'Log $120'));
      await app.settle(tester);
      expect(find.text(r'Logged $120 Car insurance'), findsOneWidget);
      // Next waiting one is September's.
      expect(find.text('Due 1 Sep 2026 · Monthly'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await app.settle(tester);
      expect(find.text(r'Log $120'), findsNothing);

      final rows = await tester.runAsync(
        () => app.db.select(app.db.expenses).get(),
      );
      final logged = rows!.where((e) => e.title == 'Car insurance').toList();
      expect(logged, hasLength(1));
      expect(logged.single.date, DateTime(2026, 8, 1));
      expect(logged.single.category, ExpenseCategory.insurance);
      // October's is scheduled as a notification.
      expect(
        app.notifications.scheduled.where(
          (n) => n.title.startsWith('Car insurance due'),
        ),
        hasLength(1),
      );
    });

    testWidgets('Edit logs a different amount through the full form', (
      tester,
    ) async {
      final app = await TestApp.start(tester, seed: seedWithInsurance);
      await tester.tap(find.text('Edit'));
      await app.settle(tester);
      expect(find.text('LOG EXPENSE'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, '131.50');
      await tester.tap(find.text('Save expense'));
      await app.settle(tester);

      final rows = await tester.runAsync(
        () => app.db.select(app.db.expenses).get(),
      );
      final logged = rows!.singleWhere((e) => e.title == 'Car insurance');
      expect(logged.amountCents, 13150);
      expect(logged.date, DateTime(2026, 8, 1));
      expect(find.text('Due 1 Sep 2026 · Monthly'), findsOneWidget);
    });

    testWidgets('an expense can be set to repeat, and managed from Expenses', (
      tester,
    ) async {
      final app = await TestApp.start(tester, seed: seedMockupGarage);
      await tester.tap(find.text('Expenses').last);
      await app.settle(tester);
      await tester.tap(find.byTooltip('Log expense'));
      await app.settle(tester);

      await tester.ensureVisible(find.text('Tolls'));
      await tester.tap(find.text('Tolls'));
      await tester.enterText(find.byType(TextFormField).first, '40');
      await tester.ensureVisible(find.text('Repeat this expense'));
      await tester.tap(
        find.descendant(
          of: find
              .ancestor(
                of: find.text('Repeat this expense'),
                matching: find.byType(Row),
              )
              .first,
          matching: find.byType(Switch),
        ),
      );
      await app.settle(tester);
      await tester.tap(find.text('Fortnightly'));
      await tester.tap(find.text('Save expense'));
      await app.settle(tester);
      expect(find.text('Expense saved · repeats fortnightly'), findsOneWidget);

      final items = await tester.runAsync(
        () => app.db.select(app.db.recurringExpenses).get(),
      );
      expect(items!.single.handledCount, 1); // Today's is already logged.

      await tester.tap(find.text('Recurring costs'));
      await app.settle(tester);
      expect(find.text('Tolls — Corolla'), findsOneWidget);
      expect(find.text('Fortnightly · next 7 Oct 2026'), findsOneWidget);
    });
  });

  testWidgets('green and pink slips show as rego approaches', (tester) async {
    final app = await TestApp.start(
      tester,
      seed: (db) async {
        await seedMockupGarage(db);
        await (db.update(db.vehicles)..where((v) => v.id.equals(1))).write(
          VehiclesCompanion(regoExpiry: Value(DateTime(2026, 10, 20))),
        );
      },
    );
    await tester.tap(find.byTooltip('Coming up'));
    await app.settle(tester);
    expect(find.text('CTP green slip — Corolla'), findsOneWidget);
    expect(find.text('Pink slip — Corolla'), findsOneWidget);
    expect(
      find.text('Safety check window open · rego 20 Oct 2026'),
      findsOneWidget,
    );
    // The 2021 CX-5 and 2017 Ranger have no rego date, so nothing for them.
    expect(find.textContaining('— CX-5'), findsNothing);
  });
}
