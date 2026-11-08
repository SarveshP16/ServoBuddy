import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/header_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../application/wash_actions.dart';
import '../domain/wash_checklist.dart';

/// Edit one checklist: remove steps, add your own, or go back to the
/// original. Changes save as you make them and apply to every car.
class ChecklistEditorScreen extends ConsumerStatefulWidget {
  const ChecklistEditorScreen({super.key, required this.kind});

  final ChecklistKind kind;

  @override
  ConsumerState<ChecklistEditorScreen> createState() =>
      _ChecklistEditorScreenState();
}

class _ChecklistEditorScreenState extends ConsumerState<ChecklistEditorScreen> {
  final _label = TextEditingController();
  var _section = ChecklistSection.outside;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  WashChecklists get _lists => ref.read(washChecklistsProvider.notifier);

  Future<void> _add(List<ChecklistItem> items) async {
    final label = _label.text.trim();
    if (label.isEmpty || items.any((i) => i.label == label)) return;
    await _lists.setItems(widget.kind, [
      ...items,
      (section: _section, label: label),
    ]);
    _label.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final items = ref.watch(washChecklistsProvider)[widget.kind]!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: '${widget.kind.label} list',
              leading: HeaderButton(
                icon: LucideIcons.chevronLeft,
                tooltip: 'Back',
                onPressed: () => context.pop(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  for (final section in ChecklistSection.values) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Text(
                        section.label.toUpperCase(),
                        style: AppText.eyebrow.copyWith(color: c.primaryText),
                      ),
                    ),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final item in items)
                            if (item.section == section)
                              ListTile(
                                title: Text(
                                  item.label,
                                  style: AppText.body.copyWith(color: c.ink),
                                ),
                                trailing: IconButton(
                                  tooltip: 'Remove ${item.label}',
                                  icon: Icon(
                                    LucideIcons.trash2,
                                    size: 18,
                                    color: c.muted,
                                  ),
                                  onPressed: () =>
                                      _lists.setItems(widget.kind, [
                                        for (final i in items)
                                          if (i != item) i,
                                      ]),
                                ),
                              ),
                          if (!items.any((i) => i.section == section))
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Text(
                                'Nothing here.',
                                style: AppText.sub.copyWith(color: c.muted),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Text(
                      'ADD A STEP',
                      style: AppText.eyebrow.copyWith(color: c.primaryText),
                    ),
                  ),
                  AppTextField(
                    controller: _label,
                    hint: 'e.g. Clean the boot',
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _add(items),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final s in ChecklistSection.values) ...[
                        ChoicePill(
                          label: s.label,
                          selected: _section == s,
                          onTap: () => setState(() => _section = s),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () => _add(items),
                        icon: const Icon(LucideIcons.plus, size: 18),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  if (_lists.isCustom(widget.kind)) ...[
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => _lists.reset(widget.kind),
                      child: const Text('Go back to the original list'),
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
