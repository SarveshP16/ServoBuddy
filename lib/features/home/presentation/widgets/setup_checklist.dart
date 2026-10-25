import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';

typedef SetupStep = ({String label, VoidCallback onTap});

/// "Finish setting up": the details the main car is missing that reminders
/// and estimates depend on. Renders nothing once there are none.
class SetupChecklist extends StatelessWidget {
  const SetupChecklist({super.key, required this.steps});

  final List<SetupStep> steps;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();
    final c = context.colors;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, step) in steps.indexed) ...[
            if (i > 0) Divider(height: 1, color: c.track),
            InkWell(
              onTap: step.onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      // A tiny plate-yellow square, like a sign's marker.
                      Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: c.highlight,
                          border: Border.all(color: c.onHighlight, width: 1.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step.label,
                          style: AppText.cardTitle.copyWith(
                            color: c.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(LucideIcons.chevronRight, size: 18, color: c.faint),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
