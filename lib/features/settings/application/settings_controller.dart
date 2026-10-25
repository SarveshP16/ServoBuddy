import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/app_settings.dart';

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).load();

  Future<void> setThemeChoice(ThemeChoice choice) =>
      _set(state.copyWith(themeChoice: choice));

  /// Blank goes back to the default; long input is trimmed to fit.
  Future<void> setGarageTitle(String title) {
    var t = title.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.length > AppSettings.garageTitleMaxLength) {
      t = t.substring(0, AppSettings.garageTitleMaxLength).trimRight();
    }
    return _set(
      state.copyWith(
        garageTitle: t.isEmpty ? AppSettings.defaultGarageTitle : t,
      ),
    );
  }

  Future<void> markBackedUp(DateTime at) =>
      _set(state.copyWith(lastBackupAt: at));

  Future<void> markNotificationPermissionsAsked() =>
      _set(state.copyWith(notificationPermissionsAsked: true));

  Future<void> _set(AppSettings next) async {
    state = next;
    await ref.read(settingsRepositoryProvider).save(next);
  }
}
