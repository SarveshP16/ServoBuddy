import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/routes.dart';
import '../../../core/database/app_database.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/calendar.dart';
import '../../../core/widgets/app_card.dart';
import '../../expenses/domain/expense_category.dart';
import '../../vehicles/domain/vehicle_labels.dart';
import '../domain/nsw_slips.dart';
import '../domain/rego_renewal.dart';

/// The rego renewal checklist: green slip, pink slip (older cars), pay. Each
/// step is ticked by logging it as a Rego expense; paying moves the expiry
/// on a year, and the card goes away until next time.
class RegoRenewalCard extends StatelessWidget {
  const RegoRenewalCard({
    super.key,
    required this.vehicle,
    required this.renewal,
    required this.today,
    this.showCarName = false,
  });

  final Vehicle vehicle;
  final RegoRenewal renewal;
  final DateTime today;

  /// On Home, where it isn't obvious which car it's for.
  final bool showCarName;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final days = daysBetween(today, renewal.expiry);
    final when = days < 0
        ? 'expired ${formatDate(renewal.expiry)}'
        : days == 0
        ? 'due today'
        : 'due ${formatDate(renewal.expiry)} · in ${formatApproxSpan(days)}';
    final urgent = days <= 14;
    return AppCard(
      padding: EdgeInsets.zero,
      borderColor: urgent ? c.warnBorder : null,
      borderWidth: 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A plate-yellow band, like the sticker the renewal replaces.
          Container(
            color: c.highlight,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: [
                Icon(LucideIcons.fileText, size: 18, color: c.onHighlight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    showCarName
                        ? 'REGO RENEWAL · ${vehicle.shortName.toUpperCase()}'
                        : 'REGO RENEWAL',
                    style: AppText.eyebrow.copyWith(color: c.onHighlight),
                  ),
                ),
                Text(
                  '${renewal.doneCount} of ${renewal.steps.length}',
                  style: AppText.label.copyWith(color: c.onHighlight),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Text(
              'Rego $when',
              style: AppText.cardTitle.copyWith(color: urgent ? c.warn : c.ink),
            ),
          ),
          for (final (i, s) in renewal.steps.indexed)
            _StepRow(
              number: i + 1,
              step: s.step,
              done: s.done,
              hint: _hint(s.step),
              onLog: () => context.push(
                AppRoutes.newExpense(
                  vehicleId: vehicle.id,
                  category: ExpenseCategory.rego.name,
                  title: s.step.title,
                  renewsRego: s.step == RenewalStep.payRego,
                ),
              ),
            ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  String _hint(RenewalStep step) => switch (step) {
    RenewalStep.greenSlip => 'Buy it before renewing',
    RenewalStep.pinkSlip =>
      'Safety check, from '
          '${formatDate(addDays(renewal.expiry, -NswSlips.pinkSlipWindowDays))}',
    RenewalStep.payRego => 'Moves the rego date on a year',
  };
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.step,
    required this.done,
    required this.hint,
    required this.onLog,
  });

  final int number;
  final RenewalStep step;
  final Expense? done;
  final String hint;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final d = done;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: d == null ? null : c.primary,
                border: Border.all(
                  color: d == null ? c.border : c.primary,
                  width: 1.5,
                ),
              ),
              child: d == null
                  ? Text(
                      '$number',
                      style: AppText.label.copyWith(color: c.muted),
                    )
                  : Icon(LucideIcons.check, size: 16, color: c.onPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: AppText.cardTitle.copyWith(
                      color: d == null ? c.ink : c.muted,
                    ),
                  ),
                  Text(
                    d == null
                        ? hint
                        : [
                            if (d.amountCents > 0) formatMoney(d.amountCents),
                            formatDate(d.date),
                          ].join(' · '),
                    style: AppText.sub.copyWith(color: c.muted),
                  ),
                ],
              ),
            ),
            if (d == null)
              TextButton(onPressed: onLog, child: const Text('Log')),
          ],
        ),
      ),
    );
  }
}
