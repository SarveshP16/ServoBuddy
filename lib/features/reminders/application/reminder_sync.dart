import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../garage/application/garage_provider.dart';
import '../../settings/application/settings_controller.dart';
import '../domain/reminder_plan.dart';

/// Keeps scheduled notifications in step with the garage: reschedules after
/// every change (debounced, since one save can touch several tables), and asks
/// for notification permissions once, the first time there's a car to remind
/// about.
final reminderSyncProvider = Provider<ReminderSync>((ref) {
  final sync = ReminderSync(ref);
  ref.listen(garageStreamProvider, (_, next) {
    if (next.hasValue) sync.schedule();
  }, fireImmediately: true);
  ref.onDispose(sync.dispose);
  return sync;
});

class ReminderSync {
  ReminderSync(this._ref);

  final Ref _ref;
  Timer? _debounce;

  void schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _run);
  }

  Future<void> _run() async {
    final garage = _ref.read(garageProvider);
    final notifications = _ref.read(notificationServiceProvider);
    try {
      if (!garage.isEmpty &&
          !_ref.read(settingsProvider).notificationPermissionsAsked) {
        await _ref
            .read(settingsProvider.notifier)
            .markNotificationPermissionsAsked();
        await notifications.init();
        await notifications.requestPermissions();
      }
      await notifications.replaceAll(
        planReminders(garage, _ref.read(clockProvider)()),
      );
    } on Exception {
      // Reminders are best-effort; a platform hiccup mustn't break the app.
    }
  }

  void dispose() => _debounce?.cancel();
}
