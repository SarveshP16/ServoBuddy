import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';
import '../support/seed.dart';

void main() {
  testWidgets('back up from Settings, then restore it', (tester) async {
    final app = await TestApp.start(tester, seed: seedMockupGarage);
    await tester.tap(find.text('Settings').last);
    await app.settle(tester);
    final list = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      find.text('Back up now'),
      200,
      scrollable: list,
    );
    expect(find.textContaining('Never backed up'), findsOneWidget);

    await tester.tap(find.text('Back up'));
    await app.settle(tester);
    expect(find.text('Backup saved'), findsOneWidget);
    expect(find.text('Last backup 23 Sep 2026'), findsOneWidget);
    expect(app.backupFiles.savedName, 'ServoBuddy-backup-2026-09-23.zip');

    // Lose a car, then bring it back from the file.
    await tester.runAsync(
      () => (app.db.delete(app.db.vehicles)..where((v) => v.id.equals(2))).go(),
    );
    await app.settle(tester);
    app.backupFiles.toOpen = app.backupFiles.saved;

    await tester.tap(find.text('Restore'));
    await app.settle(tester);
    expect(find.text('Replace everything?'), findsOneWidget);
    await tester.tap(find.text('Choose backup'));
    await app.settle(tester);
    expect(find.textContaining('Restored 3 vehicles'), findsOneWidget);

    final cars = await tester.runAsync(
      () => app.db.select(app.db.vehicles).get(),
    );
    expect(cars, hasLength(3));
  });

  testWidgets('a file that isn’t a backup is refused', (tester) async {
    final app = await TestApp.start(tester, seed: seedMockupGarage);
    await tester.tap(find.text('Settings').last);
    await app.settle(tester);
    await tester.scrollUntilVisible(
      find.text('Restore'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    app.backupFiles.toOpen = Uint8List.fromList([1, 2, 3]);

    await tester.tap(find.text('Restore'));
    await app.settle(tester);
    await tester.tap(find.text('Choose backup'));
    await app.settle(tester);
    expect(find.text('That file isn’t a ServoBuddy backup.'), findsOneWidget);
  });
}
