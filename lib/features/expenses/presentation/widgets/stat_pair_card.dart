import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';

typedef Stat = ({String label, String value});

/// Two headline numbers side by side ("ALL TIME $2,140 | THIS YEAR $740").
/// The second one's label is sign green.
class StatPairCard extends StatelessWidget {
  const StatPairCard({super.key, required this.first, required this.second});

  final Stat first;
  final Stat second;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _StatColumn(stat: first, labelColor: c.muted),
            ),
            VerticalDivider(width: 1, thickness: 1, color: c.border),
            Expanded(
              child: _StatColumn(stat: second, labelColor: c.primaryText),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.stat, required this.labelColor});

  final Stat stat;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.tiny.copyWith(
              color: labelColor,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              stat.value,
              maxLines: 1,
              style: AppText.stat.copyWith(color: c.ink, fontSize: 26),
            ),
          ),
        ],
      ),
    );
  }
}
