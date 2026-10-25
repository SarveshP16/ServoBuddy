import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servobuddy/core/theme/app_palette.dart';
import 'package:servobuddy/core/theme/app_palettes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servobuddy/core/providers.dart';
import 'package:servobuddy/features/settings/application/settings_controller.dart';
import 'package:servobuddy/features/settings/data/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/harness.dart';
import '../support/seed.dart';

void main() {
  testWidgets('settings switch between light and dark', (tester) async {
    final app = await TestApp.start(tester, seed: seedMockupGarage);
    await tester.tap(find.text('Settings').last);
    await app.settle(tester);

    expect(find.text('Reminders are on'), findsOneWidget);
    AppPalette palette() =>
        Theme.of(tester.element(find.text('Theme'))).extension<AppPalette>()!;
    expect(palette(), AppPalettes.light);
    // No colour choices any more: one look, light or dark.
    expect(find.text('Colour'), findsNothing);
    expect(find.text('Red & Black'), findsNothing);

    await tester.tap(find.text('Dark'));
    await app.settle(tester);
    expect(palette(), AppPalettes.dark);
    expect(find.text('SETTINGS'), findsOneWidget);

    await tester.tap(find.text('Light'));
    await app.settle(tester);
    expect(palette(), AppPalettes.light);
  });

  testWidgets('the Home title can be renamed, and reset', (tester) async {
    final app = await TestApp.start(tester, seed: seedMockupGarage);
    await tester.tap(find.text('Settings').last);
    await app.settle(tester);
    expect(find.text('Your Garage'), findsOneWidget); // Current value.

    Future<void> rename(String text, {String button = 'Save'}) async {
      await tester.tap(find.text('Edit'));
      await app.settle(tester);
      await tester.enterText(find.byType(TextField).last, text);
      await tester.tap(find.text(button));
      await app.settle(tester);
    }

    await rename("  Sam's   Garage ");
    await tester.tap(find.text('Settings').last);
    await app.settle(tester);
    expect(find.text("Sam's Garage"), findsOneWidget); // Tidied spaces.
    // Home sets it in capitals, like a sign.
    await tester.tap(find.text('Home').last);
    await app.settle(tester);
    expect(find.text("SAM'S GARAGE"), findsOneWidget);

    // Reset (and blank) go back to the default.
    await tester.tap(find.text('Settings').last);
    await app.settle(tester);
    await rename('', button: 'Reset');
    await tester.tap(find.text('Home').last);
    await app.settle(tester);
    expect(find.text('YOUR GARAGE'), findsOneWidget);
  });

  test('long titles are trimmed to fit', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(settingsProvider.notifier)
        .setGarageTitle('The Very Long Family Garage And Workshop');
    final title = container.read(settingsProvider).garageTitle;
    expect(title.length, lessThanOrEqualTo(AppSettings.garageTitleMaxLength));
    expect(title, 'The Very Long Family Gar'); // 24 characters.
  });
}
