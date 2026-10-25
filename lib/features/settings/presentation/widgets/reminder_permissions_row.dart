import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../../core/theme/app_palette.dart';
import 'settings_group.dart';

/// Whether reminders can actually reach you, with a fix button for each
/// missing grant. Rechecked when the app comes back from system Settings.
class ReminderPermissionsRow extends ConsumerStatefulWidget {
  const ReminderPermissionsRow({super.key});

  @override
  ConsumerState<ReminderPermissionsRow> createState() =>
      _ReminderPermissionsRowState();
}

class _ReminderPermissionsRowState extends ConsumerState<ReminderPermissionsRow>
    with WidgetsBindingObserver {
  bool? _notifications;
  bool? _exact;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final n = ref.read(notificationServiceProvider);
    try {
      await n.init();
      final notifications = await n.notificationsEnabled();
      final exact = await n.canScheduleExact();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _exact = exact;
        });
      }
    } on Exception {
      // Leave unknown; the row just shows nothing actionable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final n = ref.read(notificationServiceProvider);
    if (_notifications == null || _exact == null) {
      return const SettingsRow(title: 'Reminders', subtitle: 'Checking…');
    }
    if (_notifications == false) {
      return SettingsRow(
        title: 'Notifications are off',
        subtitle: "Service and rego reminders can't reach you.",
        subtitleWarn: true,
        trailing: TextButton(
          onPressed: () async {
            await n.requestNotificationPermission();
            await _check();
          },
          style: TextButton.styleFrom(foregroundColor: c.primaryText),
          child: const Text('Turn on'),
        ),
      );
    }
    if (_exact == false) {
      return SettingsRow(
        title: 'Reminders need one more permission',
        subtitle: 'Allow "Alarms & reminders" so they arrive on time.',
        subtitleWarn: true,
        trailing: TextButton(
          onPressed: n.requestExactAlarmPermission,
          style: TextButton.styleFrom(foregroundColor: c.primaryText),
          child: const Text('Allow'),
        ),
      );
    }
    return const SettingsRow(
      title: 'Reminders are on',
      subtitle: '2 weeks before, and on the day, at 9 am.',
    );
  }
}
