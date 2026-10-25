import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/format/money.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/icon_tile.dart';
import '../category_style.dart';

/// Icon, title, date line and amount — used for recent expenses, the
/// Expenses tab and service history.
class ExpenseRow extends StatelessWidget {
  const ExpenseRow({
    super.key,
    required this.expense,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final Expense expense;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // A service marked done without a cost shows as a record, not "$0".
    final amount = expense.amountCents == 0
        ? '—'
        : formatMoney(expense.amountCents);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          IconTile(icon: expense.category.icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardTitle.copyWith(color: c.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sub.copyWith(color: c.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(amount, style: AppText.amount.copyWith(color: c.ink)),
        ],
      ),
    );
  }
}
