import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_palette.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/car_glyph.dart';

/// The four tabs and the bar along the bottom.
class NavShell extends StatelessWidget {
  const NavShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    ('Home', LucideIcons.house),
    ('Vehicles', null),
    ('Expenses', LucideIcons.dollarSign),
    ('Settings', LucideIcons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: c.navBar,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (final (i, (label, icon)) in _tabs.indexed)
                  Expanded(
                    child: _NavItem(
                      label: label,
                      icon: icon,
                      selected: shell.currentIndex == i,
                      // Re-tapping the current tab returns to its root.
                      onTap: () => shell.goBranch(
                        i,
                        initialLocation: i == shell.currentIndex,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;

  /// Null draws the app's own car glyph (Lucide has no matching car).
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.primaryText : c.subtle;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        containedInkWell: true,
        highlightShape: BoxShape.rectangle,
        // A green bar across the top marks the open tab.
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: selected ? c.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon == null
                  ? CarGlyph(size: 24, color: color)
                  : Icon(icon, size: 22, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppText.sub.copyWith(
                  fontSize: 11.5,
                  color: color,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
