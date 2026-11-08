import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/calendar.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/form_field_label.dart';
import '../../expenses/presentation/widgets/amount_field.dart';
import '../../garage/application/garage_provider.dart';
import '../application/wash_actions.dart';
import '../domain/wash_checklist.dart';
import '../domain/wash_history.dart';
import '../domain/wash_type.dart';

/// "Log a paid wash": type, place, price, date. Saving adds it to wash history
/// and, unless a wash pass paid for it, to Expenses as Car wash. Resolves
/// true once saved.
///
/// From a finished checklist, [checklist] and the counts come along so the
/// wash records how much of it was done.
Future<bool> showPaidWashSheet(
  BuildContext context, {
  required int vehicleId,
  WashType type = WashType.automatic,
  ChecklistKind? checklist,
  int? itemsDone,
  int? itemsTotal,
  int? minutes,
}) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PaidWashSheet(
        vehicleId: vehicleId,
        initialType: type.paid ? type : WashType.automatic,
        checklist: checklist,
        itemsDone: itemsDone,
        itemsTotal: itemsTotal,
        minutes: minutes,
      ),
    ) ??
    false;

class _PaidWashSheet extends ConsumerStatefulWidget {
  const _PaidWashSheet({
    required this.vehicleId,
    required this.initialType,
    this.checklist,
    this.itemsDone,
    this.itemsTotal,
    this.minutes,
  });

  final int vehicleId;
  final WashType initialType;
  final ChecklistKind? checklist;
  final int? itemsDone;
  final int? itemsTotal;
  final int? minutes;

  @override
  ConsumerState<_PaidWashSheet> createState() => _PaidWashSheetState();
}

class _PaidWashSheetState extends ConsumerState<_PaidWashSheet> {
  final _formKey = GlobalKey<FormState>();
  final _place = TextEditingController();
  final _amount = TextEditingController();
  late var _type = widget.initialType;
  late var _date = dateOnly(ref.read(clockProvider)());
  var _usedPass = false;
  var _saving = false;

  @override
  void dispose() {
    _place.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _usePlace(({String place, WashType type, int amountCents}) p) =>
      setState(() {
        _place.text = p.place;
        _type = p.type;
        if (p.amountCents > 0) {
          _amount.text = formatMoneyExact(p.amountCents)
              .substring(1)
              .replaceAll(',', '');
        }
      });

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final logged = await ref
        .read(washActionsProvider)
        .save(
          WashDraft(
            vehicleId: widget.vehicleId,
            date: _date,
            type: _type,
            place: _place.text,
            amountCents: _usedPass ? 0 : parseMoneyToCents(_amount.text) ?? 0,
            usedPass: _usedPass,
            checklist: widget.checklist,
            itemsDone: widget.itemsDone,
            itemsTotal: widget.itemsTotal,
            minutes: widget.minutes,
          ),
        );
    if (!mounted) return;
    showAppSnackBar(
      context,
      logged > 0
          ? 'Wash saved · ${formatMoney(logged)} added to Expenses'
          : 'Wash saved',
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final places = rememberedPlaces(ref.watch(garageProvider));
    final cents = parseMoneyToCents(_amount.text) ?? 0;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Text(
              'Log a paid wash',
              style: AppText.section.copyWith(color: c.ink),
            ),
            const SizedBox(height: 4),
            Text(
              'Saved to wash history and added to Expenses as Car wash.',
              style: AppText.sub.copyWith(color: c.muted),
            ),
            const FormFieldLabel('Type', top: 16),
            ChoicePillGroup<WashType>(
              options: [
                for (final t in WashType.values)
                  if (t.paid) t,
              ],
              selected: _type,
              large: false,
              labelOf: (t) => t.label,
              onSelected: (t) => setState(() => _type = t),
            ),
            const FormFieldLabel('Where'),
            AppTextField(
              controller: _place,
              hint: 'e.g. the car wash on Main St (optional)',
              textCapitalization: TextCapitalization.words,
            ),
            if (places.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in places)
                    ChoicePill(
                      label: p.amountCents > 0
                          ? '${p.place} · ${formatMoney(p.amountCents)}'
                          : p.place,
                      selected: _place.text.trim() == p.place,
                      onTap: () => _usePlace(p),
                    ),
                ],
              ),
            ],
            if (!_usedPass) ...[
              const FormFieldLabel('Paid'),
              AmountField(
                controller: _amount,
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final cents = parseMoneyToCents(v ?? '');
                  return cents == null || cents == 0
                      ? 'Enter what you paid'
                      : null;
                },
              ),
            ],
            const FormFieldLabel('Date'),
            DateField(
              value: _date,
              lastDate: DateTime.now(),
              onChanged: (d) => setState(() => _date = d ?? _date),
            ),
            const SizedBox(height: 12),
            Material(
              color: c.warnTint,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: c.warnBorder, width: 1.5),
              ),
              child: SwitchListTile(
                value: _usedPass,
                onChanged: (v) => setState(() => _usedPass = v),
                title: Text(
                  'Paid with a wash pass',
                  style: AppText.cardTitle.copyWith(color: c.warnInk),
                ),
                subtitle: Text(
                  'Logged at \$0. Add the pass itself as a recurring cost.',
                  style: AppText.sub.copyWith(color: c.warnMuted),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(LucideIcons.check, size: 16, color: c.primaryText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _usedPass || cents == 0
                        ? 'Saved to wash history only.'
                        : 'Adds ${formatMoney(cents)} · Car wash to Expenses.',
                    style: AppText.sub.copyWith(color: c.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Save wash', busy: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
