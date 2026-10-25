import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/screen_header.dart';
import '../../backup/presentation/backup_section.dart';
import '../application/settings_controller.dart';
import '../data/app_settings.dart';
import 'widgets/garage_title_dialog.dart';
import 'widgets/reminder_permissions_row.dart';
import 'widgets/settings_group.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final version = ref.watch(packageInfoProvider).value;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const ScreenHeader(title: 'Settings', centerTitle: false),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                SettingsGroup(
                  title: 'Appearance',
                  children: [
                    SettingsRow(
                      title: 'Home title',
                      subtitle: settings.garageTitle,
                      trailing: TextButton(
                        onPressed: () async {
                          final title = await askGarageTitle(
                            context,
                            settings.garageTitle,
                          );
                          if (title != null) {
                            await controller.setGarageTitle(title);
                          }
                        },
                        child: const Text('Edit'),
                      ),
                    ),
                    SettingsControl(
                      title: 'Theme',
                      child: ChoicePillGroup<ThemeChoice>(
                        options: ThemeChoice.values,
                        selected: settings.themeChoice,
                        large: false,
                        labelOf: (c) => c.label,
                        onSelected: controller.setThemeChoice,
                      ),
                    ),
                  ],
                ),
                const SettingsGroup(
                  title: 'Reminders',
                  children: [ReminderPermissionsRow()],
                ),
                const BackupSection(),
                SettingsGroup(
                  title: 'About',
                  children: [
                    SettingsRow(
                      title: 'ServoBuddy',
                      subtitle: version == null
                          ? null
                          : 'Version ${version.version} (${version.buildNumber})',
                    ),
                    const SettingsRow(
                      title: 'Your data stays on this phone',
                      subtitle:
                          'Vehicles, expenses and photos are stored only on '
                          'this device.',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
