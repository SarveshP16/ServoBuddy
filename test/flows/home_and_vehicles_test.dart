import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';
import '../support/seed.dart';

void main() {
  testWidgets('first launch: welcome, add a car, land on its page', (
    tester,
  ) async {
    final app = await TestApp.start(tester);
    expect(find.text('Welcome to ServoBuddy'), findsOneWidget);

    await tester.tap(find.text('Add your first vehicle'));
    await app.settle(tester);
    expect(find.text('ADD VEHICLE'), findsOneWidget);

    // Saving empty shows what's missing.
    await tester.tap(find.text('Save vehicle'));
    await tester.pump();
    expect(find.text('Required'), findsNWidgets(2));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Toyota');
    await tester.enterText(fields.at(1), 'Corolla');
    await tester.enterText(fields.at(2), '2019');
    await tester.enterText(fields.at(3), '42,180');
    await tester.tap(find.text('Save vehicle'));
    await app.settle(tester);

    expect(find.text('TOYOTA COROLLA'), findsOneWidget); // Sign header.
    expect(find.text('2019 · Sedan · E10'), findsOneWidget);
    expect(find.text('ADD PLATE'), findsOneWidget);
    expect(find.text('Set up service reminders'), findsOneWidget);
    expect(find.text('42,180 km'), findsOneWidget);

    final cars = await tester.runAsync(
      () => app.db.select(app.db.vehicles).get(),
    );
    expect(cars!.single.isPrimary, isTrue);
    // Notification permission asked exactly once, now there's a car.
    expect(app.notifications.permissionRequests, 1);
  });

  testWidgets('home shows the mockup garage', (tester) async {
    await TestApp.start(tester, seed: seedMockupGarage);

    expect(find.text('Good afternoon'), findsOneWidget);
    expect(find.text('YOUR GARAGE'), findsOneWidget);
    // The main car gets the road sign, with its oil change in the strip.
    expect(find.text('TOYOTA COROLLA'), findsOneWidget);
    expect(find.text('2019 · Sedan · E10'), findsOneWidget);
    expect(find.text('Oil change due'), findsOneWidget);
    // The others ride in a strip below.
    expect(find.text('OTHER VEHICLES'), findsOneWidget);
    expect(find.text(r'$740'), findsOneWidget);
    // All of this year's spend is the Corolla's.
    expect(find.text('on 1 vehicle'), findsOneWidget);
    // The overdue Ranger outranks the Corolla's oil change.
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('Ranger · logbook service'), findsOneWidget);
    expect(find.text('Nearby fuel'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Yesterday'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // Two seeded fills plus the service, newest first.
    expect(find.text('Fuel — Corolla'), findsNWidgets(2));
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text(r'$68.40'), findsOneWidget);
  });

  testWidgets('vehicles list badges the overdue car', (tester) async {
    final app = await TestApp.start(tester, seed: seedMockupGarage);
    await tester.tap(find.text('Vehicles').last);
    await app.settle(tester);

    expect(find.text('Ford Ranger'), findsOneWidget);
    expect(find.text('Service overdue'), findsOneWidget);
    expect(find.text('Service due soon'), findsOneWidget); // Corolla.
    expect(find.text('Add vehicle'), findsOneWidget);
  });

  testWidgets('bell lists what is coming up', (tester) async {
    final app = await TestApp.start(tester, seed: seedMockupGarage);
    await tester.tap(find.byTooltip('Coming up'));
    await app.settle(tester);
    expect(find.text('Coming up'), findsWidgets);
    expect(find.text('Logbook service overdue — Ranger'), findsOneWidget);
    expect(find.text('Oil change due — Corolla'), findsOneWidget);
  });

  testWidgets('Home asks for what the main car is missing', (tester) async {
    final app = await TestApp.start(tester);
    await tester.tap(find.text('Add your first vehicle'));
    await app.settle(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Honda');
    await tester.enterText(fields.at(1), 'Civic');
    await tester.enterText(fields.at(2), '2007');
    await tester.enterText(fields.at(3), '0');
    await tester.tap(find.text('Save vehicle'));
    await app.settle(tester);
    await tester.tap(find.byTooltip('Back'));
    await app.settle(tester);

    expect(find.text('FINISH SETTING UP'), findsOneWidget);
    expect(find.text('Add the Civic’s odometer'), findsOneWidget);
    expect(find.text('Set rego expiry'), findsOneWidget);
    expect(find.text('Set up service reminders'), findsOneWidget);
    expect(find.text('No services logged yet'), findsOneWidget);
  });
}
