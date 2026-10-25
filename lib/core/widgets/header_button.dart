import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// The 44dp rounded-square buttons in screen headers: back, close, edit, add.
class HeaderButton extends StatelessWidget {
  const HeaderButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  /// Plate yellow (the "+" add button).
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(12);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? c.highlight : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: filled
              ? BorderSide(color: c.onHighlight, width: 2)
              : BorderSide(color: c.border, width: 1.5),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 44,
            child: Icon(
              icon,
              size: filled ? 22 : 20,
              color: filled ? c.onHighlight : c.ink,
            ),
          ),
        ),
      ),
    );
  }
}
