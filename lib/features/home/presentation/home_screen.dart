import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/routes.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/calendar.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/car_glyph.dart';
import '../../../core/widgets/header_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../expenses/domain/spend_summary.dart';
import '../../expenses/presentation/expense_labels.dart';
import '../../expenses/presentation/widgets/expense_row.dart';
import '../../expenses/presentation/widgets/recurring_due_section.dart';
import '../../garage/application/garage_provider.dart';
import '../../garage/domain/garage.dart';
import '../../reminders/presentation/upcoming_items.dart';
import '../../reminders/presentation/upcoming_sheet.dart';
import '../../service/presentation/due_text.dart';
import '../../settings/application/settings_controller.dart';
import '../../vehicles/domain/vehicle_labels.dart';
import 'widgets/home_vehicle_card.dart';
import 'widgets/main_vehicle_panel.dart';
import 'widgets/setup_checklist.dart';
import 'widgets/stat_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _recentCount = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final garage = ref.watch(garageProvider);
    final loaded = ref.watch(garageLoadedProvider);
    final now = ref.watch(clockProvider)();
    final urgent = upcomingItems(garage).any((i) => i.urgent);

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greetingFor(now),
                  style: AppText.body.copyWith(color: c.muted, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  ref
                      .watch(settingsProvider.select((s) => s.garageTitle))
                      .toUpperCase(),
                  style: AppText.pageTitle.copyWith(color: c.ink),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              HeaderButton(
                icon: LucideIcons.bell,
                tooltip: 'Coming up',
                onPressed: () => showUpcomingSheet(context),
              ),
              if (urgent)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: c.highlight,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.onHighlight, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    if (!loaded) return SafeArea(child: header);

    if (garage.isEmpty) {
      return SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            header,
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CarGlyph(size: 64, color: c.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Welcome to ServoBuddy',
                      style: AppText.section.copyWith(color: c.ink),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add your car to track fuel, services, rego and '
                      'running costs.',
                      textAlign: TextAlign.center,
                      style: AppText.body.copyWith(color: c.muted),
                    ),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: 'Add your first vehicle',
                      onPressed: () => context.push(AppRoutes.newVehicle),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final main = garage.primary!;
    final service = _serviceStatus(garage, main.id);
    final yearTotal = totalSpend(garage.expenses, year: garage.today.year);
    // Cars this year's spend was on (sold ones included), else cars in use.
    final spentOn = garage.expenses
        .where((e) => e.date.year == garage.today.year)
        .map((e) => e.vehicleId)
        .toSet()
        .length;
    final carCount = spentOn == 0 ? garage.vehicles.length : spentOn;
    final next = garage.mostUrgentDue;
    final recent = garage.expenses.take(_recentCount).toList();
    final others = garage.vehicles.skip(1).toList();
    final odometer = garage.odometerOf(main.id);
    final setup = <SetupStep>[
      if (odometer == null || odometer == 0)
        (
          label: 'Add the ${main.shortName}’s odometer',
          onTap: () => context.push(AppRoutes.editVehicle(main.id)),
        ),
      if (main.regoExpiry == null)
        (
          label: 'Set rego expiry',
          onTap: () => context.push(AppRoutes.editVehicle(main.id)),
        ),
      if (garage.schedulesFor(main.id).isEmpty)
        (
          label: 'Set up service reminders',
          onTap: () => context.push(AppRoutes.schedules(main.id)),
        ),
    ];

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          ListView(
            // Room under the last row for the log button.
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              header,
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: MainVehiclePanel(
                  vehicle: main,
                  serviceTitle: service.title,
                  serviceDetail: service.detail,
                  onTap: () => context.push(AppRoutes.vehicle(main.id)),
                  onServiceTap: () =>
                      context.push(AppRoutes.schedules(main.id)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: StatTile(
                          label: 'This year',
                          value: formatMoney(yearTotal),
                          caption:
                              'on $carCount '
                              '${carCount == 1 ? 'vehicle' : 'vehicles'}',
                          captionAccent: true,
                          onTap: () => context.go(AppRoutes.expenses),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatTile(
                          label: 'Next service',
                          value: next == null ? '—' : dueStatValue(next.due),
                          caption: next == null
                              ? 'No reminders set'
                              : '${next.vehicle.shortName} · '
                                    '${next.due.schedule.name.toLowerCase()}',
                          onTap: () => context.push(
                            next == null
                                ? AppRoutes.schedules(main.id)
                                : AppRoutes.vehicle(next.vehicle.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (setup.isNotEmpty) ...[
                const SectionHeader(title: 'Finish setting up'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SetupChecklist(steps: setup),
                ),
              ],
              // Recurring costs waiting to be confirmed — renders nothing if
              // none.
              const RecurringDueSection(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              ),
              if (others.isNotEmpty) ...[
                SectionHeader(
                  title: 'Other vehicles',
                  actionLabel: 'See all',
                  onAction: () => context.go(AppRoutes.vehicles),
                ),
                SizedBox(
                  height: 156,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: others.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final v = others[i];
                      return HomeVehicleCard(
                        vehicle: v,
                        odometerKm: garage.odometerOf(v.id),
                        onTap: () => context.push(AppRoutes.vehicle(v.id)),
                      );
                    },
                  ),
                ),
              ],
              SectionHeader(
                title: 'Recent',
                actionLabel: recent.isEmpty ? null : 'See all',
                onAction: () => context.go(AppRoutes.expenses),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: recent.isEmpty
                    ? AppCard(
                        onTap: () => context.push(AppRoutes.newExpense()),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.plus,
                              color: c.primaryText,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Log your first expense',
                              style: AppText.cardTitle.copyWith(
                                color: c.primaryText,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          for (final e in recent) ...[
                            ExpenseRow(
                              expense: e,
                              title:
                                  '${e.label} — '
                                  '${garage.vehicle(e.vehicleId)?.shortName ?? ''}',
                              subtitle: formatRelativeDay(e.date, garage.today),
                              onTap: () =>
                                  context.push(AppRoutes.expense(e.id)),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
              ),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 16,
            child: _LogButton(
              onPressed: () => context.push(AppRoutes.newExpense()),
            ),
          ),
        ],
      ),
    );
  }

  /// The yellow strip on the main car's panel: what's due if reminders are
  /// set up, else how long since the last service.
  static ({String title, String detail}) _serviceStatus(
    Garage garage,
    int vehicleId,
  ) {
    final due = garage.nextDueFor(vehicleId);
    if (due != null) return (title: dueHeadline(due), detail: dueDetail(due));
    final history = garage.serviceHistoryFor(vehicleId);
    if (history.isEmpty) {
      return (
        title: 'No services logged yet',
        detail: 'Add one to start tracking',
      );
    }
    final last = history.first.date;
    final days = daysBetween(last, garage.today);
    return (
      title: days <= 0
          ? 'Serviced today'
          : 'Last service ${formatApproxSpan(days)} ago',
      detail: garage.schedulesFor(vehicleId).isEmpty
          ? '${formatDate(last)} · set a reminder for the next one'
          : formatDate(last),
    );
  }
}

/// The plate-yellow "+" floating over Home's bottom-right corner.
class _LogButton extends StatelessWidget {
  const _LogButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: 'Log expense',
      child: Material(
        color: c.highlight,
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: c.onHighlight, width: 2),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox.square(
            dimension: 60,
            child: Icon(LucideIcons.plus, size: 28, color: c.onHighlight),
          ),
        ),
      ),
    );
  }
}
