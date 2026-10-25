import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_palette.dart';
import '../theme/app_typography.dart';

/// A themed text field with its label above it.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.maxLines = 1,
    this.minLines,
    this.prefixText,
    this.suffixText,
    this.style,
    this.onChanged,
    this.textInputAction,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final int? minLines;
  final String? prefixText;
  final String? suffixText;
  final TextStyle? style;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final textStyle = style ?? AppText.body.copyWith(color: c.ink);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      validator: validator,
      maxLines: maxLines,
      minLines: minLines,
      style: textStyle,
      onChanged: onChanged,
      autofocus: autofocus,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        prefixStyle: textStyle,
        suffixText: suffixText,
        suffixStyle: AppText.body.copyWith(color: c.muted),
      ),
    );
  }
}
