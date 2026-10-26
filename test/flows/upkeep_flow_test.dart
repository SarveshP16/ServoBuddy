import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servobuddy/core/database/app_database.dart';
import 'package:servobuddy/core/widgets/choice_pill.dart';

import '../support/harness.dart';
import '../support/seed.dart';

void main() {
  /// The mockup garage with the Corolla's rego due on 10 Oct, 17 days after
  /// the test's "today".
  Future<void> seedRegoDue(AppDatabase db) async {
    await seedMockupGarage(db);
    await (db.update(db.vehicles)..where((v) => v.id.equals(1))).write(
      VehiclesCompanion(regoExpiry: Value(DateTime(2026, 10, 10))),
    );
  }

  Finder logButtons() => find.widgetWithText(TextButton, 'Log');

  Future<void> logStep(
    WidgetTester tester,
    TestApp app,
    Finder button,
    String amount,
  ) async {
    await tester.ensureVisible(button);
    await tester.tap(button);
    await app.settle(tester);
    await tester.enterText(amountField, amount);
    // The last step's "Expense saved" can still be covering the button.
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .removeCurrentSnackBar();
    await app.settle(tester);
    await tester.tap(find.text('Save expense'));
    await app.settle(tester);
  }

  testWidgets('the rego checklist logs each step, then renews the rego', (
    tester,
  ) async {
    final app = await TestApp.start(tester, seed: seedRegoDue);
    // Home flags it for the car.
    expect(find.text('REGO RENEWAL · COROLLA'), findsOneWidget);
    expect(find.text('0 of 3'), findsOneWidget);

    await tester.tap(find.text('TOYOTA COROLLA'));
    await app.settle(tester);
    expect(find.text('REGO RENEWAL'), findsOneWidget);
    expect(find.text('Pink slip inspection'), findsOneWidget); // 2019 car.

    // Green slip: the form opens on Rego with the title filled in, and asks
    // for the odometer.
    await tester.ensureVisible(logButtons().first);
    await tester.tap(logButtons().first);
    await app.settle(tester);
    expect(
      tester.widget<TextFormField>(titleField).controller!.text,
      'CTP green slip',
    );
    expect(
      tester
          .widget<ChoicePill>(
            find.byWidgetPredicate((w) => w is ChoicePill && w.label == 'Rego'),
          )
          .selected,
      isTrue,
    );
    expect(find.text('Odometer now'), findsOneWidget);
    await tester.enterText(amountField, '120');
    await tester.tap(find.text('Save expense'));
    await app.settle(tester);
    expect(find.text('1 of 3'), findsOneWidget);
    expect(find.textContaining(r'$120 · 23 Sep 2026'), findsOneWidget);

    // Paying the rego moves the date on a year and the checklist goes.
    await logStep(tester, app, logButtons().last, '450');
    expect(
      find.text('Expense saved · rego now expires 10 Oct 2027'),
      findsOneWidget,
    );
    expect(find.text('REGO RENEWAL'), findsNothing);
    final car = await tester.runAsync(
      () => (app.db.select(
        app.db.vehicles,
      )..where((v) => v.id.equals(1))).getSingle(),
    );
    expect(car!.regoExpiry, DateTime(2027, 10, 10));
  });

  testWidgets('a Battery expense resets its age; it can also be cleared', (
    tester,
  ) async {
    final app = await TestApp.start(tester, seed: seedMockupGarage);
    await tester.tap(find.text('TOYOTA COROLLA'));
    await app.settle(tester);
    await tester.scrollUntilVisible(
      find.text('TYRES & BATTERY'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Not recorded'), findsNWidgets(2));

    await tester.tap(find.text('Log expense'));
    await app.settle(tester);
    await tester.ensureVisible(find.text('Repairs & parts'));
    await tester.tap(find.text('Repairs & parts'));
    await app.settle(tester);
    final battery = find.byWidgetPredicate(
      (w) => w is ChoicePill && w.label == 'Battery',
    );
    await tester.ensureVisible(battery);
    await tester.tap(battery);
    await tester.enterText(amountField, '190');
    await tester.tap(find.text('Save expense'));
    await app.settle(tester);
    expect(find.text('Expense saved · battery age reset'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('TYRES & BATTERY'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Fitted 23 Sep 2026 · just fitted'), findsOneWidget);
    expect(find.text('Replace by September 2030'), findsOneWidget);

    // Edit → forget it.
    await tester.tap(find.widgetWithText(TextButton, 'Edit'));
    await app.settle(tester);
    expect(find.text('When was the battery fitted?'), findsOneWidget);
    await tester.tap(find.text('Forget the battery date'));
    await app.settle(tester);
    expect(find.textContaining('Not recorded'), findsNWidgets(2));
  });

  testWidgets('the home screen widget gets what’s next, and opens it', (
    tester,
  ) async {
    final app = await TestApp.start(tester, seed: seedMockupGarage);
    final shown = app.homeWidget.shown!;
    expect(shown.dueTitle, 'Logbook service overdue — Ranger');
    expect(shown.monthSpend, r'$68.40');

    // A tap on the widget opens that car over Home.
    app.homeWidget.taps.add(
      Uri.parse('servobuddy://vehicle/${shown.vehicleId}'),
    );
    await app.settle(tester);
    expect(find.text('FORD RANGER'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await app.settle(tester);
    expect(find.text('YOUR GARAGE'), findsOneWidget);
  });
}
