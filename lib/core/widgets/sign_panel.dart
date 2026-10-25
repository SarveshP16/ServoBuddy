import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_typography.dart';

/// A green road-sign panel: rounded, with the white keyline signs have just
/// inside the edge. Home's main-car card and the vehicle page header.
class SignPanel extends StatelessWidget {
  const SignPanel({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.hero,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: c.onHero, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(padding: const EdgeInsets.all(14), child: child),
          ),
        ),
      ),
    );
  }
}

/// A yellow NSW number plate: the car's rego, or a prompt to add one.
class PlateBadge extends StatelessWidget {
  const PlateBadge({super.key, required this.rego});

  final String? rego;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: rego == null ? 'No number plate yet' : 'Plate $rego',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minWidth: 78),
        padding: const EdgeInsets.fromLTRB(8, 3, 8, 4),
        decoration: BoxDecoration(
          color: c.highlight,
          border: Border.all(color: c.onHighlight, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NSW',
              style: AppText.tiny.copyWith(
                color: c.onHighlight,
                fontSize: 8,
                letterSpacing: 1,
              ),
            ),
            Text(
              rego ?? 'ADD PLATE',
              style: AppText.screenTitle.copyWith(
                color: c.onHighlight,
                fontSize: rego == null ? 15 : 17,
                letterSpacing: 1.2,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
