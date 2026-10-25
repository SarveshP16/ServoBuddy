import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/routes.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/format/dates.dart';
import '../../../../core/format/money.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/icon_tile.dart';
import '../../../garage/application/garage_provider.dart';
import '../../../vehicles/domain/vehicle_labels.dart';
import '../../application/recurring_actions.dart';
import '../category_style.dart';
import '../recurring_labels.dart';

/// "Log $120?" cards for recurring costs whose due date has arrived. Nothing
/// is logged until one is tapped. Renders nothing when none are due.
class RecurringDueSection extends ConsumerWidget {
  const RecurringDueSection({super.key, this.padding = EdgeInsets.zero});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final garage = ref.watch(garageProvider);
    final pending = garage.pendingRecurring;
    if (pending.isEmpty) return const SizedBox.shrink();
    final multiCar = garage.vehicles.length > 1;
    return Padding(
      padding: padding,
      child: Column(
        children: [
          for (final p in pending) ...[
            _DueCard(
              item: p.item,
              due: p.due,
              waiting: p.waiting,
              carName: multiCar
                  ? garage.vehicle(p.item.vehicleId)?.shortName
                  : null,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _DueCard extends ConsumerWidget {
  const _DueCard({
    required this.item,
    required this.due,
    required this.waiting,
    required this.carName,
  });

  final RecurringExpense item;
  final DateTime due;

  /// How many due dates are waiting, including this one.
  final int waiting;
  final String? carName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final actions = ref.read(recurringActionsProvider);
    final amount = formatMoney(item.amountCents);
    final title = carName == null ? item.label : '${item.label} — $carName';
    final detail = [
      'Due ${formatDate(due)}',
      item.frequency.label,
      if (waiting > 1) '${waiting - 1} more waiting',
    ].join(' · ');

    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      borderColor: c.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: item.category.icon),
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
                    Text(detail, style: AppText.sub.copyWith(color: c.muted)),
                  ],
                ),
              ),
              Icon(LucideIcons.repeat, size: 16, color: c.faint),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              TextButton(
                onPressed: () async {
                  await actions.skip(item);
                  if (context.mounted) {
                    showAppSnackBar(context, 'Skipped ${item.label}');
                  }
                },
                style: TextButton.styleFrom(foregroundColor: c.muted),
                child: const Text('Skip'),
              ),
              TextButton(
                // Amount different this time? Log it through the full form.
                onPressed: () => context.push(
                  AppRoutes.newExpense(recurringId: item.id, due: due),
                ),
                style: TextButton.styleFrom(foregroundColor: c.primaryText),
                child: const Text('Edit'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  await actions.logDue(item, due);
                  if (context.mounted) {
                    showAppSnackBar(context, 'Logged $amount ${item.label}');
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: c.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: AppText.label.copyWith(fontSize: 14),
                ),
                child: Text('Log $amount'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
