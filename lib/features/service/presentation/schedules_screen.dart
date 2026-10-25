import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format/numbers.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/header_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/section_header.dart';
import '../../garage/application/garage_provider.dart';
import '../domain/schedule_presets.dart';
import '../domain/service_due.dart';
import 'due_text.dart';
import 'widgets/schedule_editor_sheet.dart';

/// A car's service reminders: what's tracked, when each is next due, and
/// one-tap presets for common ones not yet added.
class SchedulesScreen extends ConsumerWidget {
  const SchedulesScreen({super.key, required this.vehicleId});

  final int vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final garage = ref.watch(garageProvider);
    final dues = garage.duesFor(vehicleId);
    final currentKm = garage.odometerOf(vehicleId);
    final taken = dues.map((d) => d.schedule.name.toLowerCase()).toSet();
    final presets = schedulePresets
        .where((p) => !taken.contains(p.name.toLowerCase()))
        .toList();

    void edit({SchedulePreset? preset, int? scheduleId}) => showScheduleEditor(
      context,
      vehicleId: vehicleId,
      currentKm: currentKm,
      preset: preset,
      existing: scheduleId == null ? null : garage.schedule(scheduleId),
    );

    Future<void> delete(ServiceDue d) async {
      final ok = await confirmDestructive(
        context,
        title: 'Remove ${d.schedule.name}?',
        message: 'Past service records are kept.',
        confirmLabel: 'Remove',
      );
      if (!ok) return;
      await ref.read(scheduleRepositoryProvider).delete(d.schedule.id);
      if (context.mounted) {
        showAppSnackBar(context, '${d.schedule.name} reminder removed');
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Service schedule',
              leading: HeaderButton(
                icon: LucideIcons.chevronLeft,
                tooltip: 'Back',
                onPressed: () => context.pop(),
              ),
              trailing: HeaderButton(
                icon: LucideIcons.plus,
                tooltip: 'Add reminder',
                filled: true,
                onPressed: () => edit(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  if (dues.isEmpty)
                    Text(
                      'Add the services you want reminding about. Each is due '
                      'every X km or Y months, whichever comes first.',
                      style: AppText.body.copyWith(color: c.muted),
                    ),
                  for (final d in dues) ...[
                    _ScheduleRow(
                      due: d,
                      onTap: () => edit(scheduleId: d.schedule.id),
                      onDelete: () => delete(d),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (presets.isNotEmpty) ...[
                    const SectionHeader(
                      title: 'Suggestions',
                      padding: EdgeInsets.only(top: 14, bottom: 10),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final p in presets)
                          ActionChip(
                            avatar: Icon(
                              LucideIcons.plus,
                              size: 16,
                              color: c.primaryText,
                            ),
                            label: Text(p.name),
                            labelStyle: AppText.chip.copyWith(color: c.muted),
                            backgroundColor: c.surface,
                            side: BorderSide(color: c.border),
                            shape: const StadiumBorder(),
                            onPressed: () => edit(preset: p),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.due,
    required this.onTap,
    required this.onDelete,
  });

  final ServiceDue due;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = due.schedule;
    final every = [
      if (s.intervalKm != null) formatKm(s.intervalKm!),
      if (s.intervalMonths != null)
        '${s.intervalMonths} ${s.intervalMonths == 1 ? 'month' : 'months'}',
    ].join(' or ');
    final alert =
        due.status == DueStatus.overdue || due.status == DueStatus.soon;
    final status = due.status == DueStatus.unknown
        ? 'Add when it was last done'
        : '${due.status == DueStatus.overdue ? 'Overdue' : 'Due'} '
              '${dueDetail(due)}';

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name, style: AppText.cardTitle.copyWith(color: c.ink)),
                const SizedBox(height: 2),
                Text(
                  'Every $every',
                  style: AppText.sub.copyWith(color: c.muted),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: AppText.label.copyWith(
                    color: alert ? c.warn : c.primaryText,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: onDelete,
            icon: Icon(LucideIcons.trash2, size: 18, color: c.faint),
          ),
        ],
      ),
    );
  }
}
