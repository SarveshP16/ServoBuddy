import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/routes.dart';
import '../../../core/database/app_database.dart';
import '../../../core/format/money.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/calendar.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/icon_tile.dart';
import '../../../core/widgets/status_badge.dart';
import '../../garage/application/garage_provider.dart';
import '../domain/wash_history.dart';
import 'paid_wash_sheet.dart';

/// "Wash & clean" on a car's page: when it was last washed, this year's
/// washes and spend, and the two ways to record one.
class WashCard extends ConsumerWidget {
  const WashCard({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final garage = ref.watch(garageProvider);
    final history = washHistory(garage, vehicle.id);
    final stats = washStats(history, garage.today);
    final last = stats.last;
    final due = nextWashDue(vehicle, history, garage.today);
    final dueNow = due != null && !due.isAfter(garage.today);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => context.push(AppRoutes.washes(vehicle.id)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
              child: Row(
                children: [
                  const IconTile(icon: LucideIcons.droplets, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'WASH & CLEAN',
                              style: AppText.eyebrow.copyWith(
                                color: c.primaryText,
                              ),
                            ),
                            if (dueNow) ...[
                              const SizedBox(width: 8),
                              const StatusBadge(label: 'Due for a wash'),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          last == null
                              ? 'No washes yet'
                              : 'Washed ${_ago(daysBetween(last.date, garage.today))}',
                          style: AppText.stat.copyWith(
                            color: c.ink,
                            fontSize: 20,
                          ),
                        ),
                        if (last != null)
                          Text(
                            [
                              last.type?.label ?? last.title,
                              ?last.place,
                              if (last.amountCents > 0)
                                formatMoney(last.amountCents),
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.sub.copyWith(color: c.muted),
                          ),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, size: 20, color: c.faint),
                ],
              ),
            ),
          ),
          if (history.isNotEmpty)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.track)),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Stat(
                      'THIS YEAR',
                      '${stats.countThisYear} '
                          '${stats.countThisYear == 1 ? 'wash' : 'washes'}',
                    ),
                    VerticalDivider(width: 1, color: c.track),
                    _Stat('SPENT', formatMoney(stats.spendThisYear)),
                    VerticalDivider(width: 1, color: c.track),
                    _Stat(
                      'USUALLY',
                      stats.averageGapDays == null
                          ? '—'
                          : 'every ${stats.averageGapDays} d',
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: HighlightButton(
                    label: 'Start a wash',
                    onPressed: () => context.push(AppRoutes.wash(vehicle.id)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: 'Log paid wash',
                    onPressed: () =>
                        showPaidWashSheet(context, vehicleId: vehicle.id),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _ago(int days) => switch (days) {
    <= 0 => 'today',
    1 => 'yesterday',
    _ => '$days days ago',
  };
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppText.tiny.copyWith(color: c.muted, letterSpacing: 1),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AppText.cardTitle.copyWith(
                  color: c.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
