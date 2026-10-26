import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servobuddy/core/widgets/choice_pill.dart';

import '../support/harness.dart';
import '../support/seed.dart';

void main() {
  Future<TestApp> openLogExpense(WidgetTester tester) async {
    final app = await TestApp.start(tester, seed: seedMockupGarage);
    await tester.tap(find.text('Expenses').last);
    await app.settle(tester);
    await tester.tap(find.byTooltip('Log expense'));
    await app.settle(tester);
    return app;
  }

  String titleText(WidgetTester tester) =>
      tester.widget<TextFormField>(titleField).controller!.text;

  /// Scrolls the form back up to a category pill that's scrolled away.
  Future<void> category(WidgetTester tester, TestApp app, String name) async {
    await tester.scrollUntilVisible(
      find.text(name),
      -150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(name));
    await app.settle(tester);
  }

  /// A suggestion pill, not the category pill of the same name.
  Finder suggestion(String label) => find.byWidgetPredicate(
    (w) => w is ChoicePill && w.label == label && !w.large,
  );

  testWidgets('any expense can have a title, picked from suggestions', (
    tester,
  ) async {
    final app = await openLogExpense(tester);
    await tester.ensureVisible(find.text('Repairs & parts'));
    await tester.tap(find.text('Repairs & parts'));
    await app.settle(tester);

    expect(find.text('What was it?'), findsOneWidget);
    await tester.ensureVisible(suggestion('Battery'));
    await tester.tap(suggestion('Battery'));
    await tester.pump();
    expect(titleText(tester), 'Battery');
    expect(tester.widget<ChoicePill>(suggestion('Battery')).selected, isTrue);

    await tester.enterText(amountField, '190');
    await tester.tap(find.text('Save expense'));
    await app.settle(tester);

    // The list shows the title, with the category underneath.
    expect(find.text('Battery'), findsOneWidget);
    expect(find.text('Repairs & parts · Today'), findsOneWidget);
    final rows = await tester.runAsync(
      () => app.db.select(app.db.expenses).get(),
    );
    expect(rows!.where((e) => e.title == 'Battery'), hasLength(1));
  });

  testWidgets('changing category drops a suggested title, not a typed one', (
    tester,
  ) async {
    final app = await openLogExpense(tester);
    await tester.ensureVisible(find.text('Repairs & parts'));
    await tester.tap(find.text('Repairs & parts'));
    await app.settle(tester);
    await tester.ensureVisible(suggestion('Tyres'));
    await tester.tap(suggestion('Tyres'));
    await tester.pump();

    // "Tyres" isn't a toll, so it goes.
    await category(tester, app, 'Tolls');
    expect(titleText(tester), '');
    expect(suggestion('Linkt top-up'), findsOneWidget);

    // Something typed by hand stays put.
    await tester.enterText(titleField, 'Bike rack');
    await category(tester, app, 'Other');
    expect(titleText(tester), 'Bike rack');

    // Tapping the chosen suggestion again clears it.
    await tester.ensureVisible(suggestion('Fine'));
    await tester.tap(suggestion('Fine'));
    await tester.pump();
    expect(titleText(tester), 'Fine');
    await tester.tap(suggestion('Fine'));
    await tester.pump();
    expect(titleText(tester), '');
  });
}
