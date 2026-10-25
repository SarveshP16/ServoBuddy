import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/format/money.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/calendar.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/date_field.dart';
import '../../../../core/widgets/form_field_label.dart';
import '../../../expenses/presentation/widgets/amount_field.dart';
import '../../application/vehicle_actions.dart';
import '../../domain/vehicle_labels.dart';

/// Marks a car sold / not in use, with optional sold date and sale price.
/// Resolves true if it was marked.
Future<bool> showRetireVehicleSheet(BuildContext context, Vehicle v) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _RetireSheet(vehicle: v),
    ) ??
    false;

class _RetireSheet extends ConsumerStatefulWidget {
  const _RetireSheet({required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<_RetireSheet> createState() => _RetireSheetState();
}

class _RetireSheetState extends ConsumerState<_RetireSheet> {
  final _formKey = GlobalKey<FormState>();
  final _price = TextEditingController();
  late DateTime? _soldDate = dateOnly(ref.read(clockProvider)());

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final price = parseMoneyToCents(_price.text);
    await ref
        .read(vehicleActionsProvider)
        .retire(
          widget.vehicle,
          soldDate: _soldDate,
          salePriceCents: price == 0 ? null : price,
        );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Text(
              'Sold or not in use',
              style: AppText.section.copyWith(color: c.ink),
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.vehicle.displayName} moves to "Sold / not in use". '
              'Its reminders and recurring costs stop, and its history is '
              'kept. You can put it back in use any time.',
              style: AppText.sub.copyWith(color: c.muted),
            ),
            const FormFieldLabel('Sold on (optional)'),
            DateField(
              value: _soldDate,
              placeholder: 'Not sold — just not in use',
              clearable: true,
              lastDate: DateTime.now(),
              onChanged: (d) => setState(() => _soldDate = d),
            ),
            const FormFieldLabel('Sale price (optional)'),
            AmountField(
              controller: _price,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ||
                      parseMoneyToCents(v) != null
                  ? null
                  : 'Check the amount',
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Mark as sold / not in use', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
