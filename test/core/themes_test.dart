import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servobuddy/core/theme/app_palette.dart';
import 'package:servobuddy/core/theme/app_palettes.dart';
import 'package:servobuddy/core/theme/app_theme.dart';
import 'package:servobuddy/features/settings/data/app_settings.dart';
import 'package:servobuddy/features/settings/data/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WCAG contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  double lum(Color c) {
    double ch(double v) => v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  }

  final l1 = lum(a);
  final l2 = lum(b);
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

void main() {
  group('palettes stay legible', () {
    // Body text needs 4.5:1. Bold accent text and button labels are held to
    // the large-text 3:1.
    for (final (i, p) in AppPalettes.all.indexed) {
      test('palette #$i (${p.brightness.name})', () {
        void atLeast(Color fg, Color bg, double min, String what) => expect(
          contrast(fg, bg),
          greaterThanOrEqualTo(min),
          reason: '$what: ${contrast(fg, bg).toStringAsFixed(2)}:1',
        );

        atLeast(p.ink, p.background, 4.5, 'ink on page');
        atLeast(p.ink, p.surface, 4.5, 'ink on card');
        atLeast(p.muted, p.surface, 4.5, 'muted on card');
        atLeast(p.subtle, p.navBar, 3, 'nav label');
        atLeast(p.onPrimary, p.primary, 3, 'button label');
        atLeast(p.primaryText, p.surface, 3, 'accent text');
        atLeast(p.warnInk, p.warnTint, 4.5, 'warning title');
        atLeast(p.onBadge, p.badge, 4.5, 'badge');
        atLeast(p.onHero, p.hero, 4.5, 'text on the sign panel');
        atLeast(p.onHighlight, p.highlight, 4.5, 'text on plate yellow');
        atLeast(p.warn, p.surface, 3, 'warning text');
      });
    }
  });

  test('one light and one dark Road Sign palette', () {
    expect(AppPalettes.light.brightness, Brightness.light);
    expect(AppPalettes.dark.brightness, Brightness.dark);
    expect(ThemeChoice.system.mode, ThemeMode.system);
    expect(ThemeChoice.light.mode, ThemeMode.light);
    expect(ThemeChoice.dark.mode, ThemeMode.dark);
  });

  test('themes are built once and reused', () {
    expect(
      identical(themeFor(AppPalettes.light), themeFor(AppPalettes.light)),
      isTrue,
    );
    expect(themeFor(AppPalettes.dark).brightness, Brightness.dark);
    expect(
      themeFor(AppPalettes.light).extension<AppPalette>(),
      AppPalettes.light,
    );
  });

  group('settings migration from older theme settings', () {
    Future<AppSettings> load(Map<String, Object> prefs) async {
      SharedPreferences.setMockInitialValues(prefs);
      return SettingsRepository(await SharedPreferences.getInstance()).load();
    }

    test('the first light/dark setting carries over', () async {
      expect((await load({'themeMode': 'dark'})).themeChoice, ThemeChoice.dark);
      expect(
        (await load({'themeMode': 'light'})).themeChoice,
        ThemeChoice.light,
      );
      expect((await load({})).themeChoice, ThemeChoice.system);
    });

    test('Red & Black becomes Dark; the old accent is dropped', () async {
      SharedPreferences.setMockInitialValues({
        'themeChoice': 'redBlack',
        'accent': 'purple',
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepository(prefs);
      final s = repo.load();
      expect(s.themeChoice, ThemeChoice.dark);
      await repo.save(s);
      expect(prefs.getString('themeChoice'), 'dark');
      expect(prefs.containsKey('accent'), isFalse);
    });
  });
}
