import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/routes.dart';
import '../../../core/format/money.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/icon_tile.dart';
import '../../../core/widgets/status_badge.dart';
import '../../garage/application/garage_provider.dart';
import '../../vehicles/domain/vehicle_labels.dart';
import 'category_style.dart';
import 'recurring_labels.dart';
import 'widgets/stat_pair_card.dart';

/// The Recurring costs half of the Expenses tab: every recurring cost with its
/// next due date. Tap one to edit, pause or delete it.
class RecurringList extends ConsumerWidget {
  const RecurringList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final garage = ref.watch(garageProvider);
    final items = garage.recurring
        // A sold car's recurring costs reappear if it's put back in use.
        .where((r) => garage.isActive(r.vehicleId))
        .toList();
    final active = items.where((r) => !r.paused).toList();
    final perYear = active.fold(
      0,
      (sum, r) => sum + r.amountCents * r.frequency.perYear,
    );
    final multiCar = garage.vehicles.length > 1;

    if (items.isEmpty) {
      return Center(
        child: EmptyState(
          icon: const IconTile(icon: LucideIcons.repeat, size: 56),
          title: 'No recurring costs',
          message:
              'Add costs that repeat, like monthly insurance or a '
              'toll-pass top-up. On each due date you get a '
              'reminder, and a tap logs it.',
          action: PrimaryButton(
            label: 'Add recurring cost',
            onPressed: () => context.push(AppRoutes.newRecurring),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        StatPairCard(
          first: (label: 'Active', value: '${active.length}'),
          second: (label: 'Per year (est.)', value: formatMoney(perYear)),
        ),
        const SizedBox(height: 16),
        for (final r in items) ...[
          AppCard(
            onTap: () => context.push(AppRoutes.editRecurring(r.id)),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconTile(icon: r.category.icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              multiCar
                                  ? '${r.label} — '
                                        '${garage.vehicle(r.vehicleId)!.shortName}'
                                  : r.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.cardTitle.copyWith(
                                color: r.paused ? c.muted : c.ink,
                              ),
                            ),
                          ),
                          if (r.paused) ...[
                            const SizedBox(width: 6),
                            StatusBadge(
                              label: 'Paused',
                              background: c.track,
                              foreground: c.muted,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r.scheduleLine,
                        style: AppText.sub.copyWith(color: c.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatMoney(r.amountCents),
                  style: AppText.amount.copyWith(color: c.ink),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
