import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';

/// The big "$ 68.40" input.
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    this.validator,
    this.onChanged,
    this.hint = '0.00',
  });

  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final big = AppText.stat.copyWith(color: c.ink);
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      style: big,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: big.copyWith(color: c.faint),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 6),
          child: Text(r'$', style: big),
        ),
        prefixIconConstraints: const BoxConstraints(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}
