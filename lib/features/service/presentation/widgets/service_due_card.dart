import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/icon_tile.dart';
import '../../domain/service_due.dart';
import '../due_text.dart';

/// "Oil change due · in 850 km · ~3 weeks  [Mark done]". Amber (light) or
/// yellow (dark) once it's due soon or overdue; a plain card before that.
class ServiceDueCard extends StatelessWidget {
  const ServiceDueCard({
    super.key,
    required this.due,
    required this.onMarkDone,
    this.onTap,
  });

  final ServiceDue due;
  final VoidCallback onMarkDone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final alert =
        due.status == DueStatus.soon || due.status == DueStatus.overdue;
    final accent = alert ? c.warn : c.primary;
    return AppCard(
      onTap: onTap,
      color: alert ? c.warnTint : c.surface,
      borderColor: alert ? c.warnBorder : c.cardBorder,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        children: [
          IconTile(
            icon: LucideIcons.wrench,
            color: accent,
            background: alert ? c.warnTile : c.background,
            borderColor: alert ? c.warnTile : c.tileBorder,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dueHeadline(due),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardTitle.copyWith(
                    color: alert ? c.warnInk : c.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dueDetail(due),
                  maxLines: 2,
                  style: AppText.sub.copyWith(
                    color: alert ? c.warnMuted : c.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onMarkDone,
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: accent, width: 1.4),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: AppText.label.copyWith(fontSize: 13.5),
            ),
            child: const Text('Mark done'),
          ),
        ],
      ),
    );
  }
}
