import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/format/money.dart';
import '../../../../core/format/numbers.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/form_field_label.dart';

/// Litres, odometer and "filled to full" — shown only for Fuel. The price per
/// litre is worked out as you type.
class FuelFillFields extends StatelessWidget {
  const FuelFillFields({
    super.key,
    required this.litres,
    required this.odometer,
    required this.odometerHint,
    required this.fullTank,
    required this.onFullTankChanged,
    required this.amountCents,
    required this.onLitresChanged,
  });

  final TextEditingController litres;
  final TextEditingController odometer;
  final String odometerHint;
  final bool fullTank;
  final ValueChanged<bool> onFullTankChanged;
  final int? amountCents;

  /// Rebuilds the price-per-litre line as litres are typed.
  final ValueChanged<String> onLitresChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = parseDecimal(litres.text);
    final perLitre = (amountCents != null && l != null && l > 0)
        ? '${formatPricePerLitre(amountCents! / l)}/L'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FormFieldLabel('Litres'),
                  AppTextField(
                    controller: litres,
                    onChanged: onLitresChanged,
                    hint: '42.5',
                    suffixText: 'L',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? null
                        : parseDecimal(v) == null || parseDecimal(v) == 0
                        ? 'Check litres'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OdometerInput(controller: odometer, hint: odometerHint),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                perLitre == null
                    ? 'Filled to full'
                    : 'Filled to full · $perLitre',
                style: AppText.body.copyWith(color: c.ink),
              ),
            ),
            Switch(
              value: fullTank,
              onChanged: onFullTankChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        Text(
          'Fuel economy is measured between full fills.',
          style: AppText.sub.copyWith(color: c.muted),
        ),
      ],
    );
  }
}

/// Labelled optional odometer field, shared by fuel fills and services.
class OdometerInput extends StatelessWidget {
  const OdometerInput({
    super.key,
    required this.controller,
    required this.hint,
  });

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const FormFieldLabel('Odometer'),
      AppTextField(
        controller: controller,
        hint: hint,
        suffixText: 'km',
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,]'))],
        validator: (v) => (v == null || v.trim().isEmpty)
            ? null
            : parseInt(v) == null
            ? 'Whole km only'
            : null,
      ),
    ],
  );
}
