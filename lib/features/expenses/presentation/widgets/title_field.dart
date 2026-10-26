import 'package:flutter/material.dart';

import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/choice_pill.dart';
import '../../domain/expense_category.dart';
import '../../domain/title_suggestions.dart';

/// An expense's title, with the category's usual titles as pills underneath.
/// Tapping a pill fills the field; tapping the chosen one clears it.
class TitleField extends StatelessWidget {
  const TitleField({
    super.key,
    required this.controller,
    required this.category,
    this.hint = 'Add a title (optional)',
  });

  final TextEditingController controller;
  final ExpenseCategory category;
  final String hint;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppTextField(
        controller: controller,
        hint: hint,
        textCapitalization: TextCapitalization.sentences,
      ),
      const SizedBox(height: 10),
      // Rebuilds just the pills as the text changes, so the typed-in title
      // and the highlighted pill always agree.
      ValueListenableBuilder(
        valueListenable: controller,
        builder: (context, value, _) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in category.titleSuggestions)
              ChoicePill(
                label: s,
                selected: value.text.trim() == s,
                onTap: () {
                  final next = value.text.trim() == s ? '' : s;
                  controller.value = TextEditingValue(
                    text: next,
                    selection: TextSelection.collapsed(offset: next.length),
                  );
                },
              ),
          ],
        ),
      ),
    ],
  );
}
