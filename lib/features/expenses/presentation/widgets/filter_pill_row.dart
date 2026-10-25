import 'package:flutter/material.dart';

import '../../../../core/widgets/choice_pill.dart';

/// A horizontally scrolling row of filter pills, [allLabel] first (null value).
class FilterPillRow<T> extends StatelessWidget {
  const FilterPillRow({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.allLabel = 'All',
  });

  final List<T> options;
  final T? selected;
  final String Function(T) labelOf;
  final ValueChanged<T?> onSelected;
  final String allLabel;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 38,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        ChoicePill(
          label: allLabel,
          selected: selected == null,
          onTap: () => onSelected(null),
        ),
        for (final o in options) ...[
          const SizedBox(width: 8),
          ChoicePill(
            label: labelOf(o),
            selected: o == selected,
            onTap: () => onSelected(o),
          ),
        ],
      ],
    ),
  );
}
