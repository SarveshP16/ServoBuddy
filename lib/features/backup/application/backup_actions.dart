import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/data/app_settings.dart';
import '../data/backup_archive.dart';

/// Where backup files go and come from: the phone's own save and open
/// dialogs, so the user picks the folder (Downloads, a USB stick, Drive).
class BackupFiles {
  const BackupFiles();

  /// False if the user backed out of the dialog.
  Future<bool> save(String fileName, Uint8List bytes) async =>
      await FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/zip',
        dialogTitle: 'Save backup',
      ) !=
      null;

  /// Null if the user backed out.
  Future<Uint8List?> open() async {
    final file = await FilePicker.pickFile(dialogTitle: 'Choose a backup');
    return file?.xFile.readAsBytes();
  }
}

/// Swapped for a fake in tests: the real one opens system dialogs.
final backupFilesProvider = Provider<BackupFiles>((ref) => const BackupFiles());

final backupActionsProvider = Provider<BackupActions>(BackupActions.new);

class BackupActions {
  BackupActions(this._ref);

  final Ref _ref;

  BackupArchive get _archive =>
      BackupArchive(_ref.read(databaseProvider), _ref.read(imageStoreProvider));

  /// Builds the backup and asks where to save it. False if cancelled.
  Future<bool> backUp() async {
    final now = _ref.read(clockProvider)();
    final settings = _ref.read(settingsProvider);
    final bytes = await _archive.create(
      settings: (
        themeChoice: settings.themeChoice.name,
        garageTitle: settings.garageTitle,
      ),
      now: now,
    );
    final saved = await _ref
        .read(backupFilesProvider)
        .save(fileName(now), bytes);
    if (saved) {
      await _ref.read(settingsProvider.notifier).markBackedUp(now);
    }
    return saved;
  }

  /// Asks for a backup file and replaces everything with it. Null if
  /// cancelled; throws [FormatException] for a file it can't use.
  Future<RestoreSummary?> restore() async {
    final bytes = await _ref.read(backupFilesProvider).open();
    if (bytes == null) return null;
    final summary = await _archive.restore(bytes);
    if (summary.settings case final s?) {
      final settings = _ref.read(settingsProvider.notifier);
      await settings.setThemeChoice(
        ThemeChoice.values.firstWhere(
          (c) => c.name == s.themeChoice,
          orElse: () => ThemeChoice.system,
        ),
      );
      await settings.setGarageTitle(s.garageTitle);
    }
    return summary;
  }

  /// "ServoBuddy-backup-2026-10-26.zip".
  static String fileName(DateTime now) =>
      'ServoBuddy-backup-${DateFormat('yyyy-MM-dd').format(now)}.zip';
}
