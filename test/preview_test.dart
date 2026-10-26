// Dev tool, not a regression test: renders each mocked screen, light and dark,
// to test/preview/*.png at the mockups' 780x1688 size, for eyeballing against
// the reference PNGs. Skipped in normal runs; render with:
//   flutter test test/preview_test.dart --update-goldens
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servobuddy/app/app.dart';
import 'package:servobuddy/core/database/app_database.dart';
import 'package:servobuddy/features/expenses/domain/expense_category.dart';
import 'package:servobuddy/features/expenses/domain/recurrence.dart';
import 'package:servobuddy/features/vehicles/domain/vehicle_status.dart';
import 'package:servobuddy/features/settings/data/app_settings.dart';

import 'support/harness.dart';
import 'support/seed.dart';

void main() {
  final skip = !autoUpdateGoldenFiles;

  final themes = [(ThemeChoice.light, ''), (ThemeChoice.dark, '_dark')];

  for (final (theme, suffix) in themes) {
    Future<TestApp> boot(WidgetTester tester) => TestApp.start(
      tester,
      seed: seedMockupGarage,
      theme: theme,
      physicalSize: const Size(780, 1688),
      devicePixelRatio: 2,
    );

    Future<void> shot(WidgetTester tester, String name) => expectLater(
      find.byType(ServoBuddyApp),
      matchesGoldenFile('preview/$name$suffix.png'),
    );

    testWidgets('1 home$suffix', skip: skip, (tester) async {
      await boot(tester);
      await shot(tester, '1_home');
    });

    testWidgets('2 vehicles$suffix', skip: skip, (tester) async {
      final app = await boot(tester);
      await tester.tap(find.text('Vehicles').last);
      await app.settle(tester);
      await shot(tester, '2_vehicles');
    });

    testWidgets('3 detail$suffix', skip: skip, (tester) async {
      final app = await boot(tester);
      await tester.tap(find.text('TOYOTA COROLLA').first);
      await app.settle(tester);
      await shot(tester, '3_detail');
    });

    testWidgets('5 log expense$suffix', skip: skip, (tester) async {
      final app = await boot(tester);
      await tester.tap(find.text('Expenses').last);
      await app.settle(tester);
      await shot(tester, '6_expenses');
      await tester.tap(find.byTooltip('Log expense'));
      await app.settle(tester);
      await tester.enterText(titleField, 'U91');
      await tester.enterText(amountField, '68.40');
      await tester.enterText(litresField, '37.6');
      FocusManager.instance.primaryFocus?.unfocus();
      await app.settle(tester);
      await shot(tester, '5_log_expense');
    });

    testWidgets('7 settings$suffix', skip: skip, (tester) async {
      final app = await boot(tester);
      await tester.tap(find.text('Settings').last);
      await app.settle(tester);
      await shot(tester, '7_settings');
    });
  }

  // New-feature screens, light teal only.
  Future<TestApp> bootExtras(WidgetTester tester) => TestApp.start(
    tester,
    seed: (db) async {
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
              startDate: DateTime(2026, 9, 1),
            ),
          );
    },
    physicalSize: const Size(780, 1688),
    devicePixelRatio: 2,
  );

  Future<void> extraShot(WidgetTester tester, String name) => expectLater(
    find.byType(ServoBuddyApp),
    matchesGoldenFile('preview/$name.png'),
  );

  testWidgets('8 home with recurring card', skip: skip, (tester) async {
    final app = await bootExtras(tester);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await app.settle(tester);
    await extraShot(tester, '8_home_recurring');
  });

  testWidgets('11 recurring list', skip: skip, (tester) async {
    final app = await bootExtras(tester);
    await tester.tap(find.text('Expenses').last);
    await app.settle(tester);
    await extraShot(tester, '11_expenses_recurring');
    await tester.tap(find.text('Recurring costs'));
    await app.settle(tester);
    await extraShot(tester, '15_recurring_tab');
  });

  Future<TestApp> bootWithSold(WidgetTester tester) => TestApp.start(
    tester,
    seed: (db) async {
      await seedMockupGarage(db);
      await (db.update(db.vehicles)..where((v) => v.id.equals(3))).write(
        VehiclesCompanion(
          status: const Value(VehicleStatus.retired),
          soldDate: Value(DateTime(2026, 8, 14)),
          salePriceCents: const Value(1850000),
        ),
      );
    },
    physicalSize: const Size(780, 1688),
    devicePixelRatio: 2,
  );

  testWidgets('13 vehicles with sold section', skip: skip, (tester) async {
    final app = await bootWithSold(tester);
    await tester.tap(find.text('Vehicles').last);
    await app.settle(tester);
    await extraShot(tester, '13_vehicles_sold');
    await tester.tap(find.text('Ford Ranger'));
    await app.settle(tester);
    await extraShot(tester, '14_sold_detail');
  });
}
