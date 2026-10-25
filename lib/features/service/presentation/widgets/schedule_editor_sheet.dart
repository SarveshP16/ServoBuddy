import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/format/numbers.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/calendar.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/date_field.dart';
import '../../../../core/widgets/form_field_label.dart';
import '../../domain/schedule_presets.dart';

/// Add or edit one service schedule. Pass [existing] to edit, or a [preset]
/// to prefill a new one.
Future<void> showScheduleEditor(
  BuildContext context, {
  required int vehicleId,
  required int? currentKm,
  ServiceSchedule? existing,
  SchedulePreset? preset,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _ScheduleEditor(
    vehicleId: vehicleId,
    currentKm: currentKm,
    existing: existing,
    preset: preset,
  ),
);

class _ScheduleEditor extends ConsumerStatefulWidget {
  const _ScheduleEditor({
    required this.vehicleId,
    required this.currentKm,
    required this.existing,
    required this.preset,
  });

  final int vehicleId;
  final int? currentKm;
  final ServiceSchedule? existing;
  final SchedulePreset? preset;

  @override
  ConsumerState<_ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends ConsumerState<_ScheduleEditor> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _km = TextEditingController();
  final _months = TextEditingController();
  final _lastKm = TextEditingController();
  DateTime? _lastDate;
  String? _intervalError;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    final p = widget.preset;
    String fmt(int? n) => n == null ? '' : formatInt(n);
    if (s != null) {
      _name.text = s.name;
      _km.text = fmt(s.intervalKm);
      _months.text = s.intervalMonths?.toString() ?? '';
      _lastKm.text = fmt(s.baselineKm);
      _lastDate = s.baselineDate;
    } else {
      _name.text = p?.name ?? '';
      _km.text = fmt(p?.km);
      _months.text = p?.months?.toString() ?? '';
      // Most people add a schedule right after a service, so "now" is the
      // best guess; it's editable.
      _lastKm.text = fmt(widget.currentKm);
      _lastDate = dateOnly(ref.read(clockProvider)());
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _km, _months, _lastKm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final km = parseInt(_km.text);
    final months = parseInt(_months.text);
    setState(
      () => _intervalError =
          (km == null || km == 0) && (months == null || months == 0)
          ? 'Set a km interval, a months interval, or both.'
          : null,
    );
    if (!_formKey.currentState!.validate() || _intervalError != null) return;

    final repo = ref.read(scheduleRepositoryProvider);
    final lastKm = parseInt(_lastKm.text);
    final kmValue = (km == null || km == 0) ? null : km;
    final monthsValue = (months == null || months == 0) ? null : months;
    final existing = widget.existing;
    if (existing == null) {
      await repo.add(
        ServiceSchedulesCompanion.insert(
          vehicleId: widget.vehicleId,
          name: _name.text.trim(),
          intervalKm: Value(kmValue),
          intervalMonths: Value(monthsValue),
          baselineKm: Value(lastKm),
          baselineDate: Value(_lastDate),
        ),
      );
    } else {
      await repo.save(
        existing.copyWith(
          name: _name.text.trim(),
          intervalKm: Value(kmValue),
          intervalMonths: Value(monthsValue),
          baselineKm: Value(lastKm),
          baselineDate: Value(_lastDate),
        ),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final numbers = [FilteringTextInputFormatter.allow(RegExp(r'[\d,]'))];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Text(
              widget.existing == null
                  ? 'New service reminder'
                  : 'Edit reminder',
              style: AppText.section.copyWith(color: c.ink),
            ),
            const FormFieldLabel('Service'),
            AppTextField(
              controller: _name,
              hint: 'Oil change',
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const FormFieldLabel('Every'),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _km,
                    hint: '10,000',
                    suffixText: 'km',
                    keyboardType: TextInputType.number,
                    inputFormatters: numbers,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'or',
                    style: AppText.body.copyWith(color: c.muted),
                  ),
                ),
                Expanded(
                  child: AppTextField(
                    controller: _months,
                    hint: '12',
                    suffixText: 'months',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _intervalError ?? 'Whichever comes first.',
                style: AppText.sub.copyWith(
                  color: _intervalError == null ? c.muted : c.warn,
                ),
              ),
            ),
            const FormFieldLabel('Last done'),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _lastKm,
                    hint: 'Odometer',
                    suffixText: 'km',
                    keyboardType: TextInputType.number,
                    inputFormatters: numbers,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DateField(
                    value: _lastDate,
                    placeholder: 'Date',
                    lastDate: DateTime.now(),
                    onChanged: (d) => setState(() => _lastDate = d),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Service records you log later update this automatically.',
                style: AppText.sub.copyWith(color: c.muted),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Save', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
