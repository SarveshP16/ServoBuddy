import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_typography.dart';

/// A pill-shaped switch between two or more views of one screen
/// ("Expenses | Recurring costs"). The selected one slides a filled thumb.
class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final index = options.indexOf(selected);
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: ShapeDecoration(
        color: c.surface,
        shape: StadiumBorder(side: BorderSide(color: c.border, width: 1.2)),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            // -1 is the far left, 1 the far right.
            alignment: Alignment(
              options.length == 1 ? 0 : -1 + 2 * index / (options.length - 1),
              0,
            ),
            child: FractionallySizedBox(
              widthFactor: 1 / options.length,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: c.primary,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ),
          // Ink splashes draw above the thumb.
          Material(
            type: MaterialType.transparency,
            child: Row(
              children: [
                for (final o in options)
                  Expanded(
                    child: Semantics(
                      selected: o == selected,
                      button: true,
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: () => onSelected(o),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 220),
                            style: AppText.chip.copyWith(
                              color: o == selected ? c.onPrimary : c.muted,
                            ),
                            child: Text(
                              labelOf(o),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
