import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servobuddy/core/widgets/choice_pill.dart';
import 'package:servobuddy/features/expenses/domain/expense_category.dart';
import 'package:servobuddy/features/wash/domain/wash_type.dart';

import '../support/harness.dart';
import '../support/seed.dart';

void main() {
  Future<TestApp> openWashCard(WidgetTester tester) async {
    final app = await TestApp.start(tester, seed: seedMockupGarage);
    await tester.tap(find.text('TOYOTA COROLLA'));
    await app.settle(tester);
    await tester.scrollUntilVisible(
      find.text('Start a wash'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    return app;
  }

  /// Gets the last toast out of the way of buttons near the bottom.
  Future<void> clearToast(WidgetTester tester, TestApp app) async {
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .removeCurrentSnackBar();
    await app.settle(tester);
  }

  testWidgets('a paid wash is saved and logged in Expenses once', (
    tester,
  ) async {
    final app = await openWashCard(tester);
    expect(find.text('No washes yet'), findsOneWidget);

    await tester.tap(find.text('Log paid wash'));
    await app.settle(tester);
    expect(find.text('Log a paid wash'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(
        TextFormField,
        'e.g. the car wash on Main St (optional)',
      ),
      'Westside Car Wash',
    );
    final amount = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(amount.at(1), '18');
    await tester.pump();
    expect(find.text(r'Adds $18 · Car wash to Expenses.'), findsOneWidget);
    await tester.ensureVisible(find.text('Save wash'));
    await tester.tap(find.text('Save wash'));
    await app.settle(tester);

    expect(find.text(r'Wash saved · $18 added to Expenses'), findsOneWidget);
    expect(find.text('Washed today'), findsOneWidget);
    final washes = await tester.runAsync(
      () => app.db.select(app.db.washes).get(),
    );
    final expenses = await tester.runAsync(
      () => app.db.select(app.db.expenses).get(),
    );
    final logged = expenses!.where(
      (e) => e.category == ExpenseCategory.carWash,
    );
    expect(logged.single.amountCents, 1800);
    expect(logged.single.title, 'Automatic wash');
    expect(washes!.single.expenseId, logged.single.id);

    // Next time the place comes back with its price.
    await clearToast(tester, app);
    await tester.tap(find.text('Log paid wash'));
    await app.settle(tester);
    expect(
      find.byWidgetPredicate(
        (w) => w is ChoicePill && w.label == r'Westside Car Wash · $18',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a wash at home ticks off the checklist, and shows in history', (
    tester,
  ) async {
    final app = await openWashCard(tester);
    await tester.tap(find.text('Start a wash'));
    await app.settle(tester);
    expect(find.text('WASH · COROLLA'), findsOneWidget);
    expect(find.text('0 of 10 done'), findsOneWidget);

    await tester.tap(find.text('Rinse off loose dirt'));
    await tester.tap(find.text('Wheels and tyres'));
    await tester.pump();
    expect(find.text('2 of 10 done'), findsOneWidget);

    // Your own step, added to the list for next time too.
    await tester.tap(find.text('Edit list'));
    await app.settle(tester);
    expect(find.text('FULL CLEAN LIST'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Clean the boot');
    await tester.tap(find.text('Inside'));
    await tester.tap(find.text('Add'));
    await app.settle(tester);
    await tester.tap(find.byTooltip('Back'));
    await app.settle(tester);
    expect(find.text('2 of 11 done'), findsOneWidget);

    await tester.tap(find.text('Finish wash'));
    await app.settle(tester);
    expect(find.text('Wash saved · 2 of 11 done'), findsOneWidget);

    await tester.tap(find.text('Washed today'));
    await app.settle(tester);
    expect(find.text('WASH HISTORY'), findsOneWidget);
    expect(find.text('Wash at home'), findsOneWidget);
    expect(find.textContaining('Full clean 2 of 11'), findsOneWidget);
    expect(find.text('Free'), findsOneWidget);

    // Wash reminder: every 3 weeks.
    await tester.tap(find.text('3 wks'));
    await app.settle(tester);
    final car = await tester.runAsync(
      () => (app.db.select(
        app.db.vehicles,
      )..where((v) => v.id.equals(1))).getSingle(),
    );
    expect(car!.washEveryDays, 21);
    final washes = await tester.runAsync(
      () => app.db.select(app.db.washes).get(),
    );
    expect(washes!.single.type, WashType.home);
    expect(washes.single.expenseId, isNull);
  });

  testWidgets('deleting a paid wash can keep its expense', (tester) async {
    final app = await openWashCard(tester);
    await tester.tap(find.text('Log paid wash'));
    await app.settle(tester);
    final fields = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(fields.at(1), '25');
    await tester.ensureVisible(find.text('Save wash'));
    await tester.tap(find.text('Save wash'));
    await app.settle(tester);

    await tester.tap(find.text('Washed today'));
    await app.settle(tester);
    await tester.tap(find.text('Automatic wash'));
    await app.settle(tester);
    expect(find.text('Delete this automatic wash?'), findsOneWidget);
    await tester.tap(find.text('Keep the expense'));
    await app.settle(tester);

    expect(
      await tester.runAsync(() => app.db.select(app.db.washes).get()),
      isEmpty,
    );
    // The expense stays, and shows in history as one from Expenses.
    expect(find.textContaining('from Expenses'), findsOneWidget);
  });
}
