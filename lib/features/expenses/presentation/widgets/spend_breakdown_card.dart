import 'package:flutter/material.dart';

import '../../../../core/format/money.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/expense_category.dart';
import '../category_style.dart';

/// "This year $640" with a bar per category that has any spend.
class SpendBreakdownCard extends StatelessWidget {
  const SpendBreakdownCard({super.key, required this.byCategory});

  final Map<ExpenseCategory, int> byCategory;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final total = byCategory.values.fold(0, (a, b) => a + b);
    final rows = ExpenseCategory.values
        .where((cat) => byCategory[cat]! > 0)
        .toList();

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'THIS YEAR',
                  style: AppText.tiny.copyWith(
                    color: c.muted,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                formatMoney(total),
                style: AppText.stat.copyWith(color: c.ink, fontSize: 26),
              ),
            ],
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nothing logged this year yet.',
                  style: AppText.sub.copyWith(color: c.muted),
                ),
              ),
            ),
          for (final cat in rows)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 104,
                    child: Text(
                      cat.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sub.copyWith(color: c.muted),
                    ),
                  ),
                  Expanded(
                    child: _Bar(
                      // Share of the year's total, as mocked ($410 of $640
                      // fills 64% of the track).
                      fraction: byCategory[cat]! / total,
                      color: cat.barColor(c),
                      track: c.track,
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(
                      formatMoney(byCategory[cat]!),
                      textAlign: TextAlign.right,
                      style: AppText.label.copyWith(color: c.ink),
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

class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.color,
    required this.track,
  });

  final double fraction;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) => Container(
    height: 8,
    decoration: BoxDecoration(
      color: track,
      borderRadius: BorderRadius.circular(4),
    ),
    alignment: Alignment.centerLeft,
    child: FractionallySizedBox(
      widthFactor: fraction.clamp(0.04, 1.0),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    ),
  );
}
