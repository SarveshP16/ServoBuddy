import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/routes.dart';
import '../../../core/database/app_database.dart';
import '../../../core/format/dates.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/icon_tile.dart';
import '../../../core/widgets/sign_panel.dart';
import '../../../core/widgets/section_header.dart';
import '../../expenses/domain/expense_category.dart';
import '../../expenses/domain/spend_summary.dart';
import '../../expenses/presentation/expense_labels.dart';
import '../../expenses/presentation/widgets/expense_row.dart';
import '../../expenses/presentation/widgets/spend_breakdown_card.dart';
import '../../garage/application/garage_provider.dart';
import '../../reminders/domain/nsw_slips.dart';
import '../../service/presentation/widgets/service_due_card.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../application/vehicle_actions.dart';
import '../domain/vehicle_labels.dart';
import '../domain/vehicle_status.dart';
import 'widgets/retired_banner.dart';
import 'widgets/vehicle_facts_card.dart';
import 'widgets/vehicle_image.dart';

class VehicleDetailScreen extends ConsumerWidget {
  const VehicleDetailScreen({super.key, required this.vehicleId});

  final int vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final garage = ref.watch(garageProvider);
    final v = garage.vehicle(vehicleId);
    if (v == null || v.status == VehicleStatus.deleted) {
      // Deleted (or a stale link): nothing to show.
      return const Scaffold(body: SizedBox.shrink());
    }
    final retired = v.status == VehicleStatus.retired;

    final due = garage.nextDueFor(v.id);
    final hasSchedules = garage.schedulesFor(v.id).isNotEmpty;
    final history = garage.serviceHistoryFor(v.id);
    return Scaffold(
      body: Column(
        children: [
          _SignHeader(vehicle: v),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      children: [
                        if (v.photoPath != null) ...[
                          VehicleImage(
                            photoPath: v.photoPath,
                            height: 150,
                            radius: 14,
                            glyphSize: 80,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (retired) ...[
                          RetiredBanner(
                            vehicle: v,
                            lifetimeSpendCents: garage.lifetimeSpend(v.id),
                          ),
                          const SizedBox(height: 16),
                        ],
                        SpendBreakdownCard(
                          byCategory: spendByCategory(
                            garage.expensesFor(v.id),
                            year: garage.today.year,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // A car out of use has nothing coming due.
                        if (retired)
                          const SizedBox.shrink()
                        else if (due != null)
                          ServiceDueCard(
                            due: due,
                            onTap: () =>
                                context.push(AppRoutes.schedules(v.id)),
                            onMarkDone: () => context.push(
                              AppRoutes.newExpense(
                                vehicleId: v.id,
                                category: ExpenseCategory.service.name,
                                scheduleId: due.schedule.id,
                              ),
                            ),
                          )
                        else
                          _SetUpScheduleCard(
                            hasSchedules: hasSchedules,
                            onTap: () =>
                                context.push(AppRoutes.schedules(v.id)),
                          ),
                        if (!retired) const SizedBox(height: 16),
                        VehicleFactsCard(
                          odometerKm: garage.odometerOf(v.id),
                          fuel: garage.fuelStatsFor(v.id),
                          regoExpiry: v.regoExpiry,
                          insuranceExpiry: v.insuranceExpiry,
                          today: garage.today,
                          pinkSlipFrom: nswSlipsFor(
                            v,
                            garage.today,
                          )?.pinkSlipFrom,
                        ),
                        SectionHeader(
                          title: 'Service history',
                          actionLabel: retired ? null : 'Schedule',
                          onAction: () =>
                              context.push(AppRoutes.schedules(v.id)),
                          padding: const EdgeInsets.only(top: 12, bottom: 12),
                        ),
                        if (history.isEmpty)
                          Text(
                            'No services logged yet.',
                            style: AppText.sub.copyWith(color: c.muted),
                          ),
                        for (final e in history) ...[
                          ExpenseRow(
                            expense: e,
                            title: e.label,
                            subtitle: formatDatePadded(e.date),
                            onTap: () => context.push(AppRoutes.expense(e.id)),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: c.border)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                      child: retired
                          ? PrimaryButton(
                              label: 'Put back in use',
                              onPressed: () async {
                                await ref
                                    .read(vehicleActionsProvider)
                                    .restore(v);
                                if (context.mounted) {
                                  showAppSnackBar(
                                    context,
                                    '${v.displayName} is back in use',
                                  );
                                }
                              },
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: HighlightButton(
                                    label: 'Log expense',
                                    onPressed: () => context.push(
                                      AppRoutes.newExpense(vehicleId: v.id),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: PrimaryButton(
                                    label: 'Add service record',
                                    onPressed: () => context.push(
                                      AppRoutes.newExpense(
                                        vehicleId: v.id,
                                        category: ExpenseCategory.service.name,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The car's road sign across the top: back and edit, its name in condensed
/// capitals, what it is, and its plate. Status-bar icons go white over it.
class _SignHeader extends StatelessWidget {
  const _SignHeader({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final v = vehicle;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: ColoredBox(
        color: c.hero,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _OnSignButton(
                      icon: LucideIcons.chevronLeft,
                      tooltip: 'Back',
                      onPressed: () => context.pop(),
                    ),
                    _OnSignButton(
                      icon: LucideIcons.penLine,
                      tooltip: 'Edit vehicle',
                      onPressed: () =>
                          context.push(AppRoutes.editVehicle(v.id)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.displayName.toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.display.copyWith(
                              color: c.onHero,
                              fontSize: 36,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${v.year} · ${v.bodyType.label} · '
                            '${v.fuelType.label}',
                            style: AppText.body.copyWith(
                              color: c.onHero.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    PlateBadge(rego: v.rego),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A header button drawn for the green panel: white outline, white icon.
class _OnSignButton extends StatelessWidget {
  const _OnSignButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(12);
    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: c.onHero.withValues(alpha: 0.55), width: 1.5),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 44,
            child: Icon(icon, size: 20, color: c.onHero),
          ),
        ),
      ),
    );
  }
}

/// Shown instead of the due card when nothing is due-trackable yet.
class _SetUpScheduleCard extends StatelessWidget {
  const _SetUpScheduleCard({required this.hasSchedules, required this.onTap});

  final bool hasSchedules;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const IconTile(icon: LucideIcons.bellRing),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasSchedules
                      ? 'Service reminders need a last-done'
                      : 'Set up service reminders',
                  style: AppText.cardTitle.copyWith(color: c.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  hasSchedules
                      ? 'Add when each was last done to see what’s due.'
                      : 'Oil changes, logbook services, tyres — every X km or '
                            'Y months.',
                  style: AppText.sub.copyWith(color: c.muted),
                ),
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, size: 20, color: c.faint),
        ],
      ),
    );
  }
}
