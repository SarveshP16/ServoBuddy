import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/routes.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/header_button.dart';
import '../../../core/widgets/icon_tile.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/segmented_tabs.dart';
import '../../garage/application/garage_provider.dart';
import '../../garage/domain/garage.dart';
import '../../vehicles/domain/vehicle_labels.dart';
import '../application/expense_actions.dart';
import '../domain/expense_category.dart';
import '../domain/spend_summary.dart';
import 'expense_labels.dart';
import 'recurring_list.dart';
import 'widgets/expense_row.dart';
import 'widgets/filter_pill_row.dart';
import 'widgets/recurring_due_section.dart';
import 'widgets/stat_pair_card.dart';

enum _Section {
  expenses('Expenses'),
  recurring('Recurring costs');

  const _Section(this.label);

  final String label;
}

/// The Expenses tab, split into Expenses and Recurring costs.
///
/// Expenses: all-time and yearly totals up top, then every expense newest
/// first, grouped by month, filterable by year, car and category. Swipe left
/// to delete (with Undo).
class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  var _section = _Section.expenses;
  int? _year;
  int? _vehicleId;
  ExpenseCategory? _category;

  @override
  Widget build(BuildContext context) {
    final garage = ref.watch(garageProvider);
    // Recurring costs belong to a car, so there's nothing to show without one.
    final section = garage.isEmpty ? _Section.expenses : _section;
    final onRecurring = section == _Section.recurring;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          ScreenHeader(
            title: 'Expenses',
            centerTitle: false,
            trailing: onRecurring
                ? HeaderButton(
                    icon: LucideIcons.plus,
                    tooltip: 'Add recurring cost',
                    filled: true,
                    onPressed: () => context.push(AppRoutes.newRecurring),
                  )
                : HeaderButton(
                    icon: LucideIcons.plus,
                    tooltip: 'Log expense',
                    filled: true,
                    onPressed: () => context.push(AppRoutes.newExpense()),
                  ),
          ),
          if (!garage.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: SegmentedTabs<_Section>(
                options: _Section.values,
                selected: section,
                labelOf: (s) => s.label,
                onSelected: (s) => setState(() => _section = s),
              ),
            ),
          Expanded(
            child: onRecurring ? const RecurringList() : _expenses(garage),
          ),
        ],
      ),
    );
  }

  Widget _expenses(Garage garage) {
    final c = context.colors;
    if (garage.expenses.isEmpty) {
      return Column(
        children: [
          const RecurringDueSection(padding: EdgeInsets.fromLTRB(20, 0, 20, 0)),
          Expanded(
            child: Center(
              child: EmptyState(
                icon: IconTile(icon: LucideIcons.receipt, size: 56),
                title: 'No expenses yet',
                message:
                    'Log fuel, services, rego and insurance to see where '
                    'the money goes.',
              ),
            ),
          ),
        ],
      );
    }

    final today = garage.today;
    // A filtered-on car that's since been deleted falls back to All, as does
    // a year that no longer has any expenses.
    final vehicleId = garage.vehicle(_vehicleId ?? -1)?.id;
    final years = expenseYears(garage.expenses, current: today.year);
    final year = years.contains(_year) ? _year : null;

    // Totals follow the car and category filters, not the year one.
    final matching = garage.expenses
        .where((e) => vehicleId == null || e.vehicleId == vehicleId)
        .where((e) => _category == null || e.category == _category)
        .toList();
    final totalYear = year ?? today.year;
    final groups = groupByMonth(
      matching.where((e) => year == null || e.date.year == year).toList(),
    );

    // Name the car on each row once expenses span more than one (sold cars
    // included — their history stays here).
    final multiCar = garage.expenses.map((e) => e.vehicleId).toSet().length > 1;
    final filterCars = [...garage.vehicles, ...garage.retiredVehicles];
    const gutter = EdgeInsets.symmetric(horizontal: 20);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const RecurringDueSection(padding: gutter),
        Padding(
          padding: gutter,
          child: StatPairCard(
            first: (label: 'All time', value: formatMoney(sumCents(matching))),
            second: (
              label: totalYear == today.year
                  ? 'This year · $totalYear'
                  : 'In $totalYear',
              value: formatMoney(totalSpend(matching, year: totalYear)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (years.length > 1) ...[
          FilterPillRow<int>(
            options: years,
            selected: year,
            allLabel: 'All years',
            labelOf: (y) => '$y',
            onSelected: (y) => setState(() => _year = y),
          ),
          const SizedBox(height: 8),
        ],
        if (filterCars.length > 1) ...[
          FilterPillRow<int>(
            options: [for (final v in filterCars) v.id],
            selected: vehicleId,
            labelOf: (id) => garage.vehicle(id)!.displayName,
            onSelected: (id) => setState(() => _vehicleId = id),
          ),
          const SizedBox(height: 8),
        ],
        FilterPillRow<ExpenseCategory>(
          options: ExpenseCategory.values,
          selected: _category,
          labelOf: (cat) => cat.label,
          onSelected: (cat) => setState(() => _category = cat),
        ),
        const SizedBox(height: 4),
        if (groups.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Text(
              'Nothing matches these filters.',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: c.muted),
            ),
          ),
        for (final g in groups)
          Padding(
            padding: gutter,
            child: Column(
              children: [
                _MonthHeader(month: g.month, totalCents: g.totalCents),
                for (final e in g.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Dismissible(
                      key: ValueKey('expense-${e.id}'),
                      direction: DismissDirection.endToStart,
                      background: _DeleteBackground(),
                      onDismissed: (_) => ref
                          .read(expenseActionsProvider)
                          .deleteWithUndo(context, e),
                      child: ExpenseRow(
                        expense: e,
                        title: multiCar
                            ? '${e.label} — ${garage.vehicle(e.vehicleId)?.shortName ?? ''}'
                            : e.label,
                        subtitle: [
                          if (e.title != null) e.category.label,
                          formatRelativeDay(e.date, today),
                          ?e.fuelDetail,
                        ].join(' · '),
                        onTap: () => context.push(AppRoutes.expense(e.id)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.month, required this.totalCents});

  final DateTime month;
  final int totalCents;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              formatMonth(month).toUpperCase(),
              style: AppText.eyebrow.copyWith(color: c.primaryText),
            ),
          ),
          Text(
            formatMoney(totalCents),
            style: AppText.eyebrow.copyWith(color: c.primaryText),
          ),
        ],
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: c.warn,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(LucideIcons.trash2, color: c.onPrimary),
    );
  }
}
