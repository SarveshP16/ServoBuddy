import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servobuddy/core/database/app_database.dart';
import 'package:servobuddy/features/expenses/domain/expense_category.dart';
import 'package:servobuddy/features/expenses/domain/recurrence.dart';
import 'package:servobuddy/features/vehicles/domain/vehicle_status.dart';

import '../support/harness.dart';
import '../support/seed.dart';

/// The mockup garage, plus a monthly toll pass and a rego date on the Corolla
/// (so it has recurring and renewal reminders to lose when sold).
Future<void> seed(AppDatabase db) async {
  await seedMockupGarage(db);
  await (db.update(db.vehicles)..where((v) => v.id.equals(1))).write(
    VehiclesCompanion(regoExpiry: Value(DateTime(2026, 12, 1))),
  );
  await db
      .into(db.recurringExpenses)
      .insert(
        RecurringExpensesCompanion.insert(
          vehicleId: 1,
          category: ExpenseCategory.tolls,
          amountCents: 4000,
          title: const Value('Toll pass'),
          frequency: RecurFrequency.monthly,
          startDate: DateTime(2026, 9, 1),
        ),
      );
}

Future<void> openEditCorolla(WidgetTester tester, TestApp app) async {
  await tester.tap(find.text('TOYOTA COROLLA').first);
  await app.settle(tester);
  await tester.tap(find.byTooltip('Edit vehicle'));
  await app.settle(tester);
}

bool mentionsCorolla(TestApp app) => app.notifications.scheduled.any(
  (n) => n.title.contains('Corolla') || n.title.startsWith('Toll pass'),
);

void main() {
  testWidgets('sold: moves to its own section, reminders stop, history stays', (
    tester,
  ) async {
    final app = await TestApp.start(tester, seed: seed);
    expect(mentionsCorolla(app), isTrue);
    expect(find.text(r'Log $40'), findsOneWidget); // Toll pass is due.

    await openEditCorolla(tester, app);
    await tester.scrollUntilVisible(
      find.text('Mark as sold / not in use'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Mark as sold / not in use'));
    await app.settle(tester);
    await tester.enterText(find.byType(TextFormField).last, '14500');
    await tester.tap(find.text('Mark as sold / not in use').last);
    await app.settle(tester);

    // Vehicles tab: under Sold / not in use, with the date.
    expect(find.text('SOLD / NOT IN USE'), findsOneWidget);
    expect(find.text('Sold 23 Sep 2026'), findsOneWidget);

    // Gone from Home and its reminders; the Mazda is now the main car.
    await tester.tap(find.text('Home').last);
    await app.settle(tester);
    expect(find.text('Toyota Corolla'), findsNothing);
    expect(find.text(r'Log $40'), findsNothing);
    expect(mentionsCorolla(app), isFalse);

    final cars = await tester.runAsync(
      () => app.db.select(app.db.vehicles).get(),
    );
    final corolla = cars!.firstWhere((v) => v.model == 'Corolla');
    expect(corolla.status, VehicleStatus.retired);
    expect(corolla.salePriceCents, 1450000);
    expect(cars.firstWhere((v) => v.model == 'CX-5').isPrimary, isTrue);

    // Its expenses still count.
    expect(find.text(r'$740'), findsOneWidget);

    // Its page: sale details and cost of ownership; then back in use.
    await tester.tap(find.text('Vehicles').last);
    await app.settle(tester);
    await tester.tap(find.text('Toyota Corolla'));
    await app.settle(tester);
    expect(find.text('Sold 23 Sep 2026'), findsOneWidget);
    expect(find.text(r'$14,500'), findsOneWidget);
    expect(find.text('Mark done'), findsNothing);
    await tester.tap(find.text('Put back in use'));
    await app.settle(tester);
    expect(find.text('Toyota Corolla is back in use'), findsOneWidget);
    expect(mentionsCorolla(app), isTrue);
  });

  testWidgets('delete but keep history: expenses stay, the car goes', (
    tester,
  ) async {
    final app = await TestApp.start(tester, seed: seed);
    await openEditCorolla(tester, app);
    await tester.tap(find.byTooltip('Delete vehicle'));
    await app.settle(tester);
    await tester.tap(find.text('Delete, keep expense history'));
    await app.settle(tester);

    expect(
      find.text('Toyota Corolla deleted — its expenses are kept'),
      findsOneWidget,
    );
    expect(find.text('Toyota Corolla'), findsNothing); // Not even under Sold.
    expect(find.text('SOLD / NOT IN USE'), findsNothing);
    expect(mentionsCorolla(app), isFalse);

    final db = app.db;
    final left = await tester.runAsync(
      () async => (
        expenses: await db.select(db.expenses).get(),
        schedules: await db.select(db.serviceSchedules).get(),
        recurring: await db.select(db.recurringExpenses).get(),
      ),
    );
    expect(left!.expenses, hasLength(5));
    expect(left.schedules.where((s) => s.vehicleId == 1), isEmpty);
    expect(left.recurring, isEmpty);

    // Still in Expenses, under the old car's name.
    await tester.tap(find.text('Expenses').last);
    await app.settle(tester);
    expect(find.text('Logbook service'), findsOneWidget);
  });

  testWidgets('delete everything removes all of it', (tester) async {
    final app = await TestApp.start(tester, seed: seed);
    await openEditCorolla(tester, app);
    await tester.tap(find.byTooltip('Delete vehicle'));
    await app.settle(tester);
    await tester.tap(find.text('Delete everything'));
    await app.settle(tester);

    final db = app.db;
    final left = await tester.runAsync(
      () async => (
        cars: await db.select(db.vehicles).get(),
        expenses: await db.select(db.expenses).get(),
      ),
    );
    expect(left!.cars.map((v) => v.model), isNot(contains('Corolla')));
    expect(left.expenses, isEmpty);
  });
}
