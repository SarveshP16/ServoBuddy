import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_typography.dart';

/// Bold caption above a form field, with the gap below it built in.
class FormFieldLabel extends StatelessWidget {
  const FormFieldLabel(this.text, {super.key, this.top = 20});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: top, bottom: 8),
    child: Text(text, style: AppText.label.copyWith(color: context.colors.ink)),
  );
}
