import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_typography.dart';

/// A pill-shaped single-select chip (vehicle, category, fuel type).
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.large = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// The Log expense form uses bigger pills than its compact rows.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? c.primary : c.surface,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? c.primary : c.border, width: 1.5),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: large ? 16 : 14,
              vertical: large ? 11 : 9,
            ),
            child: Text(
              label,
              style: (large ? AppText.cardTitle : AppText.chip).copyWith(
                color: selected ? c.onPrimary : c.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wrapping row of [ChoicePill]s for one value out of [options].
class ChoicePillGroup<T> extends StatelessWidget {
  const ChoicePillGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.large = true,
  });

  final List<T> options;
  final T? selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  final bool large;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final o in options)
        ChoicePill(
          label: labelOf(o),
          selected: o == selected,
          large: large,
          onTap: () => onSelected(o),
        ),
    ],
  );
}
