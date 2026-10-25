import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// The small rounded square behind a list row's icon.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.size = 36,
    this.color,
    this.background,
    this.borderColor,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final Color? background;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? c.tile,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: borderColor ?? c.tileBorder),
      ),
      child: Icon(icon, size: size * 0.5, color: color ?? c.primary),
    );
  }
}
