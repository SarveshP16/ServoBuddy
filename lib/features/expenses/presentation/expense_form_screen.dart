import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/routes.dart';
import '../../../core/database/app_database.dart';
import '../../../core/format/money.dart';
import '../../../core/format/numbers.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/calendar.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/car_glyph.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/form_field_label.dart';
import '../../../core/widgets/header_button.dart';
import '../../../core/widgets/photo_field.dart';
import '../../../core/widgets/screen_header.dart';
import '../../garage/application/garage_provider.dart';
import '../../vehicles/domain/vehicle_labels.dart';
import '../application/expense_actions.dart';
import '../application/recurring_actions.dart';
import '../domain/expense_category.dart';
import '../domain/recurrence.dart';
import '../domain/title_suggestions.dart';
import 'recurring_labels.dart';
import 'widgets/amount_field.dart';
import 'widgets/fuel_fill_fields.dart';
import 'widgets/title_field.dart';

/// Log an expense, or edit one when [expenseId] is given.
///
/// Service records are Service-category expenses, so "Add service record" and
/// "Mark done" open this same form preset to Service (and to a schedule).
class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({
    super.key,
    this.expenseId,
    this.initialVehicleId,
    this.initialCategory,
    this.initialScheduleId,
    this.recurringId,
    this.recurringDue,
  });

  final int? expenseId;
  final int? initialVehicleId;
  final ExpenseCategory? initialCategory;
  final int? initialScheduleId;

  /// Logging a recurring cost's due payment (its "Edit" button): prefilled
  /// from it, and saving moves it on to its next due date.
  final int? recurringId;
  final DateTime? recurringDue;

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _litres = TextEditingController();
  final _odometer = TextEditingController();
  final _title = TextEditingController();
  final _notes = TextEditingController();

  int? _vehicleId;
  var _category = ExpenseCategory.fuel;

  /// Service only: which schedule this record satisfies (null = "Other").
  int? _scheduleId;
  late DateTime _date;
  var _fullTank = true;
  String? _receiptPath;
  bool _saving = false;

  /// Set when logging a recurring cost's due payment.
  RecurringExpense? _fromRecurring;

  /// "Repeat this expense": also creates a recurring cost on save.
  var _repeat = false;
  var _repeatFrequency = RecurFrequency.monthly;

  Expense? _original;

  bool get _editing => widget.expenseId != null;

  @override
  void initState() {
    super.initState();
    final garage = ref.read(garageProvider);
    _date = dateOnly(ref.read(clockProvider)());
    final e = widget.expenseId == null
        ? null
        : garage.expense(widget.expenseId!);
    if (e != null) {
      _original = e;
      _vehicleId = e.vehicleId;
      _category = e.category;
      _scheduleId = e.scheduleId;
      _date = e.date;
      _fullTank = e.fullTank;
      _receiptPath = e.receiptPath;
      _amount.text = e.amountCents == 0
          ? ''
          : formatMoneyExact(e.amountCents).substring(1).replaceAll(',', '');
      _litres.text = e.litres?.toString() ?? '';
      _odometer.text = e.odometerKm == null ? '' : formatInt(e.odometerKm!);
      // A service done against a schedule takes the schedule's name.
      _title.text = e.scheduleId == null ? (e.title ?? '') : '';
      _notes.text = e.notes ?? '';
      return;
    }
    final r = widget.recurringId == null
        ? null
        : garage.recurringById(widget.recurringId!);
    if (r != null) {
      _fromRecurring = r;
      _vehicleId = r.vehicleId;
      _category = r.category;
      _date = widget.recurringDue ?? r.nextDue;
      _amount.text = formatMoneyExact(r.amountCents)
          .substring(1)
          .replaceAll(',', '');
      _title.text = r.title ?? '';
      return;
    }
    _vehicleId = garage.isActive(widget.initialVehicleId ?? -1)
        ? widget.initialVehicleId
        : garage.primary?.id;
    _category = widget.initialCategory ?? ExpenseCategory.fuel;
    if (widget.initialScheduleId != null &&
        garage.schedule(widget.initialScheduleId!)?.vehicleId == _vehicleId) {
      _category = ExpenseCategory.service;
      _scheduleId = widget.initialScheduleId;
    }
  }

  @override
  void dispose() {
    for (final c in [_amount, _litres, _odometer, _title, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _costOptional => _category == ExpenseCategory.service;

  /// Switching category drops a title picked from the old category's
  /// suggestions ("Battery" isn't a toll), but keeps one typed by hand.
  void _setCategory(ExpenseCategory c) => setState(() {
    if (_category.titleSuggestions.contains(_title.text.trim())) {
      _title.clear();
    }
    _category = c;
  });

  String? _validateAmount(String? v) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) return _costOptional ? null : 'Enter the amount';
    final cents = parseMoneyToCents(text);
    if (cents == null) return 'Check the amount';
    if (cents == 0 && !_costOptional) return 'Enter the amount';
    return null;
  }

  Future<void> _save() async {
    if (_vehicleId == null || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final garage = ref.read(garageProvider);
    final isFuel = _category == ExpenseCategory.fuel;
    final isService = _category == ExpenseCategory.service;
    final schedule = isService && _scheduleId != null
        ? garage.schedule(_scheduleId!)
        : null;
    final customTitle = _title.text.trim();
    final notes = _notes.text.trim();
    final draft = ExpenseDraft(
      vehicleId: _vehicleId!,
      category: _category,
      amountCents: parseMoneyToCents(_amount.text) ?? 0,
      date: _date,
      title: schedule?.name ?? (customTitle.isEmpty ? null : customTitle),
      notes: notes.isEmpty ? null : notes,
      receiptPath: _receiptPath,
      litres: isFuel ? parseDecimal(_litres.text) : null,
      fullTank: _fullTank,
      odometerKm: (isFuel || isService) ? parseInt(_odometer.text) : null,
      scheduleId: schedule?.id,
    );
    final actions = ref.read(expenseActionsProvider);
    try {
      if (_original == null) {
        await actions.create(draft);
      } else {
        await actions.update(_original!, draft);
      }
      final recurring = ref.read(recurringActionsProvider);
      if (_fromRecurring != null) {
        await recurring.markLogged(_fromRecurring!.id);
      } else if (_repeat && !_editing) {
        // This expense is the first payment; the next is one period on.
        await recurring.create(
          RecurringDraft(
            vehicleId: draft.vehicleId,
            category: draft.category,
            amountCents: draft.amountCents,
            title: draft.title,
            frequency: _repeatFrequency,
            nextDue: _date,
          ),
          firstAlreadyLogged: true,
        );
      }
      if (!mounted) return;
      showAppSnackBar(
        context,
        _editing
            ? 'Expense updated'
            : _repeat
            ? 'Expense saved · repeats ${_repeatFrequency.label.toLowerCase()}'
            : isService
            ? 'Service record saved'
            : 'Expense saved',
      );
      context.pop();
    } on Exception {
      if (mounted) {
        setState(() => _saving = false);
        showAppSnackBar(context, "Couldn't save. Try again.");
      }
    }
  }

  Future<void> _delete() async {
    await ref.read(expenseActionsProvider).deleteWithUndo(context, _original!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final garage = ref.watch(garageProvider);
    final isFuel = _category == ExpenseCategory.fuel;
    final isService = _category == ExpenseCategory.service;
    final schedules = _vehicleId == null
        ? const <ServiceSchedule>[]
        : garage.schedulesFor(_vehicleId!);
    final currentKm = _vehicleId == null
        ? null
        : garage.odometerOf(_vehicleId!);
    final odometerHint = currentKm == null
        ? 'Optional'
        : 'Last ${formatInt(currentKm)}';

    final header = ScreenHeader(
      title: _editing
          ? 'Edit expense'
          : isService
          ? 'Service record'
          : 'Log expense',
      leading: HeaderButton(
        icon: LucideIcons.x,
        tooltip: 'Close',
        onPressed: () => context.pop(),
      ),
      trailing: _editing
          ? HeaderButton(
              icon: LucideIcons.trash2,
              tooltip: 'Delete expense',
              onPressed: _delete,
            )
          : null,
    );

    if (garage.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              header,
              Expanded(
                child: Center(
                  child: EmptyState(
                    icon: CarGlyph(size: 56, color: context.colors.primary),
                    title: 'Add a vehicle first',
                    message: 'Expenses are logged against a vehicle.',
                    action: PrimaryButton(
                      label: 'Add vehicle',
                      onPressed: () =>
                          context.pushReplacement(AppRoutes.newVehicle),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            header,
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    const FormFieldLabel('Vehicle', top: 0),
                    ChoicePillGroup<int>(
                      // In-use cars, plus this expense's own car when editing
                      // one logged against a car since sold.
                      options: [
                        for (final v in garage.vehicles) v.id,
                        if (_original != null &&
                            !garage.isActive(_original!.vehicleId))
                          _original!.vehicleId,
                      ],
                      selected: _vehicleId,
                      labelOf: (id) => garage.vehicle(id)!.displayName,
                      onSelected: (id) => setState(() {
                        _vehicleId = id;
                        _scheduleId = null; // Schedules belong to one car.
                      }),
                    ),
                    const FormFieldLabel('Category'),
                    ChoicePillGroup<ExpenseCategory>(
                      options: ExpenseCategory.values,
                      selected: _category,
                      labelOf: (c) => c.label,
                      onSelected: _setCategory,
                    ),
                    if (isService) ...[
                      const FormFieldLabel('Service'),
                      ChoicePillGroup<int?>(
                        options: [for (final s in schedules) s.id, null],
                        selected: _scheduleId,
                        large: false,
                        labelOf: (id) =>
                            id == null ? 'Other' : garage.schedule(id)!.name,
                        onSelected: (id) => setState(() => _scheduleId = id),
                      ),
                      if (_scheduleId == null) ...[
                        const SizedBox(height: 10),
                        TitleField(
                          controller: _title,
                          category: _category,
                          hint: 'What was done (e.g. Logbook service)',
                        ),
                      ],
                    ] else ...[
                      const FormFieldLabel('What was it?'),
                      TitleField(controller: _title, category: _category),
                    ],
                    FormFieldLabel(
                      _costOptional ? 'Cost (optional)' : 'Amount',
                    ),
                    AmountField(
                      controller: _amount,
                      validator: _validateAmount,
                      // Fuel's price-per-litre line updates as you type.
                      onChanged: isFuel ? (_) => setState(() {}) : null,
                    ),
                    if (isFuel)
                      FuelFillFields(
                        litres: _litres,
                        odometer: _odometer,
                        odometerHint: odometerHint,
                        fullTank: _fullTank,
                        onFullTankChanged: (v) => setState(() => _fullTank = v),
                        amountCents: parseMoneyToCents(_amount.text),
                        onLitresChanged: (_) => setState(() {}),
                      ),
                    if (isService)
                      OdometerInput(controller: _odometer, hint: odometerHint),
                    const FormFieldLabel('Date'),
                    DateField(
                      value: _date,
                      lastDate: DateTime.now(),
                      onChanged: (d) => setState(() => _date = d ?? _date),
                    ),
                    if (!_editing && _fromRecurring == null)
                      _RepeatField(
                        repeat: _repeat,
                        frequency: _repeatFrequency,
                        onRepeat: (v) => setState(() => _repeat = v),
                        onFrequency: (f) =>
                            setState(() => _repeatFrequency = f),
                      ),
                    const FormFieldLabel('Notes'),
                    AppTextField(
                      controller: _notes,
                      hint: 'Add a note (optional)',
                      maxLines: 4,
                      minLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const FormFieldLabel('Receipt'),
                    PhotoField(
                      path: _receiptPath,
                      addLabel: 'Attach receipt (optional)',
                      height: 180,
                      onChanged: (p) => setState(() => _receiptPath = p),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: PrimaryButton(
                label: isService && !_editing ? 'Save service' : 'Save expense',
                busy: _saving,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Repeat this expense" with a frequency picker once switched on.
class _RepeatField extends StatelessWidget {
  const _RepeatField({
    required this.repeat,
    required this.frequency,
    required this.onRepeat,
    required this.onFrequency,
  });

  final bool repeat;
  final RecurFrequency frequency;
  final ValueChanged<bool> onRepeat;
  final ValueChanged<RecurFrequency> onFrequency;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Repeat this expense',
                    style: AppText.cardTitle.copyWith(color: c.ink),
                  ),
                  Text(
                    "You'll be reminded to log it each time.",
                    style: AppText.sub.copyWith(color: c.muted),
                  ),
                ],
              ),
            ),
            Switch(
              value: repeat,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: onRepeat,
            ),
          ],
        ),
        if (repeat) ...[
          const SizedBox(height: 10),
          ChoicePillGroup<RecurFrequency>(
            options: RecurFrequency.values,
            selected: frequency,
            large: false,
            labelOf: (f) => f.label,
            onSelected: onFrequency,
          ),
        ],
      ],
    );
  }
}
