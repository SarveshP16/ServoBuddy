import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/dates.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/presentation/widgets/settings_group.dart';
import '../application/backup_actions.dart';

/// Settings' "Backup" card: save everything to a file, or restore from one.
class BackupSection extends ConsumerStatefulWidget {
  const BackupSection({super.key});

  @override
  ConsumerState<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends ConsumerState<BackupSection> {
  var _busy = false;

  Future<void> _run(Future<String?> Function() job) async {
    setState(() => _busy = true);
    String? message;
    try {
      message = await job();
    } on FormatException catch (e) {
      message = e.message == 'Made by a newer version of ServoBuddy'
          ? 'That backup is from a newer ServoBuddy. Update the app first.'
          : 'That file isn’t a ServoBuddy backup.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (message != null && mounted) showAppSnackBar(context, message);
  }

  Future<void> _backUp() => _run(() async {
    final saved = await ref.read(backupActionsProvider).backUp();
    return saved ? 'Backup saved' : null;
  });

  Future<void> _restore() async {
    final ok = await confirmDestructive(
      context,
      title: 'Replace everything?',
      message:
          'Restoring swaps every vehicle, expense, reminder and photo on this '
          'phone for the ones in the backup. Back up first if you might want '
          'today’s data back.',
      confirmLabel: 'Choose backup',
    );
    if (!ok || !mounted) return;
    await _run(() async {
      final s = await ref.read(backupActionsProvider).restore();
      if (s == null) return null;
      return 'Restored ${_count(s.vehicles, 'vehicle')} and '
          '${_count(s.expenses, 'expense')}';
    });
  }

  static String _count(int n, String noun) => '$n $noun${n == 1 ? '' : 's'}';

  @override
  Widget build(BuildContext context) {
    final last = ref.watch(settingsProvider.select((s) => s.lastBackupAt));
    return SettingsGroup(
      title: 'Backup',
      children: [
        SettingsRow(
          title: 'Back up now',
          subtitle: last == null
              ? 'Never backed up. Saves vehicles, expenses, reminders and '
                    'photos to one file.'
              : 'Last backup ${formatDate(last)}',
          subtitleWarn: last == null,
          trailing: TextButton(
            onPressed: _busy ? null : _backUp,
            child: const Text('Back up'),
          ),
        ),
        SettingsRow(
          title: 'Restore from backup',
          subtitle: 'Replaces everything on this phone with a backup file.',
          trailing: TextButton(
            onPressed: _busy ? null : _restore,
            child: const Text('Restore'),
          ),
        ),
      ],
    );
  }
}
