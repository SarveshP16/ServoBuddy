import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/routes.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/calendar.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/form_field_label.dart';
import '../../../core/widgets/header_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/segmented_tabs.dart';
import '../../garage/application/garage_provider.dart';
import '../../vehicles/domain/vehicle_labels.dart';
import '../application/wash_actions.dart';
import '../domain/wash_checklist.dart';
import '../domain/wash_type.dart';
import 'paid_wash_sheet.dart';

/// "Start a wash": pick how and which checklist, tick things off, Finish.
/// A wash at home is saved straight away; a paid one goes on to the paid-wash
/// sheet for the price.
class WashChecklistScreen extends ConsumerStatefulWidget {
  const WashChecklistScreen({super.key, required this.vehicleId});

  final int vehicleId;

  @override
  ConsumerState<WashChecklistScreen> createState() =>
      _WashChecklistScreenState();
}

class _WashChecklistScreenState extends ConsumerState<WashChecklistScreen> {
  var _type = WashType.home;
  var _kind = ChecklistKind.full;

  /// Ticked items by label, so switching checklist keeps what's shared.
  final _done = <String>{};
  late final DateTime _started = ref.read(clockProvider)();
  var _saving = false;

  Future<void> _finish(List<ChecklistItem> items) async {
    final done = items.where((i) => _done.contains(i.label)).length;
    final minutes = ref.read(clockProvider)().difference(_started).inMinutes;
    if (_type.paid) {
      final saved = await showPaidWashSheet(
        context,
        vehicleId: widget.vehicleId,
        type: _type,
        checklist: _kind,
        itemsDone: done,
        itemsTotal: items.length,
        minutes: minutes,
      );
      if (saved && mounted) context.pop();
      return;
    }
    setState(() => _saving = true);
    await ref
        .read(washActionsProvider)
        .save(
          WashDraft(
            vehicleId: widget.vehicleId,
            date: dateOnly(ref.read(clockProvider)()),
            type: _type,
            checklist: _kind,
            itemsDone: done,
            itemsTotal: items.length,
            minutes: minutes,
          ),
        );
    if (!mounted) return;
    showAppSnackBar(context, 'Wash saved · $done of ${items.length} done');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final v = ref.watch(garageProvider).vehicle(widget.vehicleId);
    final items = ref.watch(washChecklistsProvider)[_kind]!;
    final done = items.where((i) => _done.contains(i.label)).length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Wash · ${v?.shortName ?? ''}',
              leading: HeaderButton(
                icon: LucideIcons.x,
                tooltip: 'Close',
                onPressed: () => context.pop(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  const FormFieldLabel('How are you washing it?', top: 0),
                  ChoicePillGroup<WashType>(
                    options: WashType.values,
                    selected: _type,
                    large: false,
                    labelOf: (t) => t.label,
                    onSelected: (t) => setState(() => _type = t),
                  ),
                  const SizedBox(height: 16),
                  SegmentedTabs<ChecklistKind>(
                    options: ChecklistKind.values,
                    selected: _kind,
                    labelOf: (k) => k.label,
                    onSelected: (k) => setState(() => _kind = k),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '$done of ${items.length} done',
                          style: AppText.cardTitle.copyWith(
                            color: c.ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: items.isEmpty ? 0 : done / items.length,
                            minHeight: 10,
                            backgroundColor: c.track,
                            color: c.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final section in ChecklistSection.values)
                    if (items.where((i) => i.section == section).toList()
                        case final rows when rows.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 18, bottom: 8),
                        child: Text(
                          section.label.toUpperCase(),
                          style: AppText.eyebrow.copyWith(color: c.primaryText),
                        ),
                      ),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (final (i, item) in rows.indexed) ...[
                              if (i > 0) Divider(height: 1, color: c.track),
                              CheckboxListTile(
                                value: _done.contains(item.label),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                onChanged: (on) => setState(
                                  () => on!
                                      ? _done.add(item.label)
                                      : _done.remove(item.label),
                                ),
                                title: Text(
                                  item.label,
                                  style: AppText.body.copyWith(
                                    color: _done.contains(item.label)
                                        ? c.muted
                                        : c.ink,
                                    decoration: _done.contains(item.label)
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: OutlineButton(
                        label: 'Edit list',
                        onPressed: () =>
                            context.push(AppRoutes.washChecklist(_kind)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PrimaryButton(
                        label: _type.paid
                            ? 'Finish · add price'
                            : 'Finish wash',
                        busy: _saving,
                        onPressed: () => _finish(items),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
