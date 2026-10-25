import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/format/dates.dart';
import '../../../../core/format/money.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/icon_tile.dart';

/// Top of a sold / not-in-use car's page: when it left, what it sold for, and
/// what it cost to own overall.
class RetiredBanner extends StatelessWidget {
  const RetiredBanner({
    super.key,
    required this.vehicle,
    required this.lifetimeSpendCents,
  });

  final Vehicle vehicle;
  final int lifetimeSpendCents;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sold = vehicle.soldDate;
    final price = vehicle.salePriceCents;
    final rows = [
      ('Spent while owned', formatMoney(lifetimeSpendCents)),
      if (price != null) ('Sold for', formatMoney(price)),
      // Purchase price isn't tracked, so this is running costs less what it
      // sold for; negative when the sale more than covered them.
      if (price != null)
        ('Net cost (spent − sale)', _signed(lifetimeSpendCents - price)),
    ];

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: LucideIcons.archive, color: c.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sold == null ? 'Not in use' : 'Sold ${formatDate(sold)}',
                      style: AppText.cardTitle.copyWith(color: c.ink),
                    ),
                    Text(
                      'No reminders. History is kept.',
                      style: AppText.sub.copyWith(color: c.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: AppText.sub.copyWith(color: c.muted),
                    ),
                  ),
                  Text(value, style: AppText.label.copyWith(color: c.ink)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// "$1,240" or "−$18,500".
String _signed(int cents) =>
    cents < 0 ? '−${formatMoney(-cents)}' : formatMoney(cents);
