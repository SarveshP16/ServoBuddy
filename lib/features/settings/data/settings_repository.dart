import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _themeKey = 'themeChoice';

  /// From when there were Teal, Ember and Purple accents. Cleared on save.
  static const _oldAccentKey = 'accent';
  static const _permissionsAskedKey = 'notificationPermissionsAsked';
  static const _garageTitleKey = 'garageTitle';
  static const _lastBackupKey = 'lastBackupAt';

  /// Before accents existed the only setting was system/light/dark.
  static const _legacyThemeKey = 'themeMode';

  AppSettings load() => AppSettings(
    themeChoice: _themeChoice(),
    notificationPermissionsAsked: _prefs.getBool(_permissionsAskedKey) ?? false,
    garageTitle:
        _prefs.getString(_garageTitleKey) ?? AppSettings.defaultGarageTitle,
    lastBackupAt: DateTime.tryParse(_prefs.getString(_lastBackupKey) ?? ''),
  );

  ThemeChoice _themeChoice() {
    final saved =
        _prefs.getString(_themeKey) ?? _prefs.getString(_legacyThemeKey);
    return switch (saved) {
      'light' => ThemeChoice.light,
      // The retired Red & Black theme was a dark one.
      'dark' || 'redBlack' => ThemeChoice.dark,
      _ => ThemeChoice.system,
    };
  }

  Future<void> save(AppSettings s) async {
    await _prefs.setString(_themeKey, s.themeChoice.name);
    await _prefs.remove(_oldAccentKey);
    await _prefs.setBool(_permissionsAskedKey, s.notificationPermissionsAsked);
    await _prefs.setString(_garageTitleKey, s.garageTitle);
    if (s.lastBackupAt case final at?) {
      await _prefs.setString(_lastBackupKey, at.toIso8601String());
    }
  }
}
