import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/database/app_database.dart';
import '../../../core/format/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/calendar.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/form_field_label.dart';
import '../../../core/widgets/header_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../garage/application/garage_provider.dart';
import '../../vehicles/domain/vehicle_labels.dart';
import '../application/recurring_actions.dart';
import '../domain/expense_category.dart';
import '../domain/recurrence.dart';
import 'recurring_labels.dart';
import 'widgets/amount_field.dart';

/// Add a recurring cost, or edit one when [recurringId] is given.
class RecurringFormScreen extends ConsumerStatefulWidget {
  const RecurringFormScreen({super.key, this.recurringId});

  final int? recurringId;

  @override
  ConsumerState<RecurringFormScreen> createState() =>
      _RecurringFormScreenState();
}

class _RecurringFormScreenState extends ConsumerState<RecurringFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _title = TextEditingController();

  int? _vehicleId;
  var _category = ExpenseCategory.insurance;
  var _frequency = RecurFrequency.monthly;
  late DateTime _nextDue;
  var _paused = false;
  RecurringExpense? _original;

  @override
  void initState() {
    super.initState();
    final garage = ref.read(garageProvider);
    _nextDue = dateOnly(ref.read(clockProvider)());
    _vehicleId = garage.primary?.id;
    final r = widget.recurringId == null
        ? null
        : garage.recurringById(widget.recurringId!);
    if (r == null) return;
    _original = r;
    _vehicleId = r.vehicleId;
    _category = r.category;
    _frequency = r.frequency;
    _nextDue = r.nextDue;
    _paused = r.paused;
    _title.text = r.title ?? '';
    _amount.text = formatMoneyExact(r.amountCents)
        .substring(1)
        .replaceAll(',', '');
  }

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_vehicleId == null || !_formKey.currentState!.validate()) return;
    final title = _title.text.trim();
    final draft = RecurringDraft(
      vehicleId: _vehicleId!,
      category: _category,
      amountCents: parseMoneyToCents(_amount.text)!,
      title: title.isEmpty ? null : title,
      frequency: _frequency,
      nextDue: _nextDue,
    );
    final actions = ref.read(recurringActionsProvider);
    if (_original == null) {
      await actions.create(draft);
    } else {
      await actions.update(_original!, draft);
      if (_paused != _original!.paused) {
        final fresh = ref.read(garageProvider).recurringById(_original!.id);
        if (fresh != null) await actions.setPaused(fresh, _paused);
      }
    }
    if (!mounted) return;
    showAppSnackBar(context, 'Recurring cost saved');
    context.pop();
  }

  Future<void> _delete() async {
    final ok = await confirmDestructive(
      context,
      title: 'Delete ${_original!.label}?',
      message: 'Expenses already logged from it are kept.',
    );
    if (!ok || !mounted) return;
    await ref.read(recurringActionsProvider).delete(_original!.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final garage = ref.watch(garageProvider);
    final editing = _original != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: editing ? 'Edit recurring cost' : 'Recurring cost',
              leading: HeaderButton(
                icon: LucideIcons.x,
                tooltip: 'Close',
                onPressed: () => context.pop(),
              ),
              trailing: editing
                  ? HeaderButton(
                      icon: LucideIcons.trash2,
                      tooltip: 'Delete recurring cost',
                      onPressed: _delete,
                    )
                  : null,
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    const FormFieldLabel('Vehicle', top: 0),
                    ChoicePillGroup<int>(
                      options: [for (final v in garage.vehicles) v.id],
                      selected: _vehicleId,
                      labelOf: (id) => garage.vehicle(id)!.displayName,
                      onSelected: (id) => setState(() => _vehicleId = id),
                    ),
                    const FormFieldLabel('Category'),
                    ChoicePillGroup<ExpenseCategory>(
                      options: ExpenseCategory.values,
                      selected: _category,
                      labelOf: (cat) => cat.label,
                      onSelected: (cat) => setState(() => _category = cat),
                    ),
                    const FormFieldLabel('Description'),
                    AppTextField(
                      controller: _title,
                      hint: 'e.g. Linkt top-up (optional)',
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const FormFieldLabel('Amount'),
                    AmountField(
                      controller: _amount,
                      validator: (v) {
                        final cents = parseMoneyToCents(v ?? '');
                        return cents == null || cents == 0
                            ? 'Enter the amount'
                            : null;
                      },
                    ),
                    const FormFieldLabel('Repeats'),
                    ChoicePillGroup<RecurFrequency>(
                      options: RecurFrequency.values,
                      selected: _frequency,
                      large: false,
                      labelOf: (f) => f.label,
                      onSelected: (f) => setState(() => _frequency = f),
                    ),
                    FormFieldLabel(editing ? 'Next due' : 'First due'),
                    DateField(
                      value: _nextDue,
                      onChanged: (d) =>
                          setState(() => _nextDue = d ?? _nextDue),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        "You'll get a reminder on each due date. Nothing is "
                        'logged until you confirm it.',
                        style: AppText.sub.copyWith(color: c.muted),
                      ),
                    ),
                    if (editing) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Paused',
                                  style: AppText.cardTitle.copyWith(
                                    color: c.ink,
                                  ),
                                ),
                                Text(
                                  'No reminders while paused.',
                                  style: AppText.sub.copyWith(color: c.muted),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _paused,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onChanged: (v) => setState(() => _paused = v),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: PrimaryButton(label: 'Save', onPressed: _save),
            ),
          ],
        ),
      ),
    );
  }
}
