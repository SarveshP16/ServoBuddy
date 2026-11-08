import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/routes.dart';
import '../../../core/database/app_database.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/header_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../expenses/presentation/category_style.dart';
import '../../expenses/domain/expense_category.dart';
import '../../garage/application/garage_provider.dart';
import '../application/wash_actions.dart';
import '../domain/wash_checklist.dart';
import '../domain/wash_history.dart';
import '../domain/wash_type.dart';

/// Every wash for one car, by month, with this year's totals, how you tend
/// to wash, and the wash reminder.
class WashHistoryScreen extends ConsumerWidget {
  const WashHistoryScreen({super.key, required this.vehicleId});

  final int vehicleId;

  /// Reminder choices, in days.
  static const _reminders = <int?>[null, 14, 21, 28, 42];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final garage = ref.watch(garageProvider);
    final v = garage.vehicle(vehicleId);
    final history = washHistory(garage, vehicleId);
    final stats = washStats(history, garage.today);

    final months = <DateTime, List<WashEntry>>{};
    for (final e in history) {
      months.putIfAbsent(DateTime(e.date.year, e.date.month), () => []).add(e);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Wash history',
              leading: HeaderButton(
                icon: LucideIcons.chevronLeft,
                tooltip: 'Back',
                onPressed: () => context.pop(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  Row(
                    children: [
                      _Tile('THIS YEAR', '${stats.countThisYear}', 'washes'),
                      const SizedBox(width: 8),
                      _Tile(
                        'SPENT',
                        formatMoney(stats.spendThisYear),
                        stats.countThisYear == 0
                            ? 'this year'
                            : '${formatMoney(stats.spendThisYear ~/ stats.countThisYear)} a wash',
                      ),
                      const SizedBox(width: 8),
                      _Tile(
                        'GAP',
                        stats.averageGapDays == null
                            ? '—'
                            : '${stats.averageGapDays} d',
                        'on average',
                      ),
                    ],
                  ),
                  if (stats.byType.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _TypeMix(byType: stats.byType),
                  ],
                  if (v != null) ...[
                    const SizedBox(height: 10),
                    AppCard(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Remind me to wash',
                            style: AppText.cardTitle.copyWith(color: c.ink),
                          ),
                          Text(
                            'Counted from the last wash.',
                            style: AppText.sub.copyWith(color: c.muted),
                          ),
                          const SizedBox(height: 10),
                          ChoicePillGroup<int?>(
                            options: _reminders,
                            selected: v.washEveryDays,
                            large: false,
                            labelOf: (d) => d == null ? 'Off' : '${d ~/ 7} wks',
                            onSelected: (d) => ref
                                .read(washActionsProvider)
                                .setWashEvery(vehicleId, d),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (history.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 32),
                      child: EmptyState(
                        icon: Icon(LucideIcons.droplets, size: 48),
                        title: 'No washes yet',
                        message:
                            'Start a wash with a checklist, or log one you '
                            'paid for, from the car’s page.',
                      ),
                    ),
                  for (final MapEntry(key: month, value: entries)
                      in months.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 18, bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              formatMonth(month).toUpperCase(),
                              style: AppText.eyebrow.copyWith(
                                color: c.primaryText,
                              ),
                            ),
                          ),
                          Text(
                            formatMoney(
                              entries.fold(0, (s, e) => s + e.amountCents),
                            ),
                            style: AppText.eyebrow.copyWith(
                              color: c.primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final (i, e) in entries.indexed) ...[
                            if (i > 0) Divider(height: 1, color: c.track),
                            _WashRow(entry: e),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.value, this.caption);

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
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
                style: AppText.stat.copyWith(color: c.ink, fontSize: 22),
              ),
            ),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.sub.copyWith(color: c.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// "How you wash": a bar split by type, this year.
class _TypeMix extends StatelessWidget {
  const _TypeMix({required this.byType});

  final Map<WashType, int> byType;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final colours = {
      WashType.automatic: c.highlight,
      WashType.home: c.primary,
      WashType.hand: c.otherBar,
      WashType.detail: c.insuranceBar,
    };
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOW YOU WASH',
            style: AppText.tiny.copyWith(color: c.muted, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 12,
              child: Row(
                // Stretch, or the bare colour boxes would be 0 high.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 2,
                children: [
                  for (final MapEntry(key: t, value: n) in byType.entries)
                    Expanded(
                      flex: n,
                      child: ColoredBox(color: colours[t]!),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              for (final MapEntry(key: t, value: n) in byType.entries)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colours[t],
                        borderRadius: BorderRadius.circular(2),
                        border: t == WashType.automatic
                            ? Border.all(color: c.onHighlight)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${t.label} $n',
                      style: AppText.sub.copyWith(color: c.muted),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WashRow extends ConsumerWidget {
  const _WashRow({required this.entry});

  final WashEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final e = entry;
    final w = e.wash;
    final checklist = w?.checklist == null
        ? null
        : ChecklistKind.values.where((k) => k.name == w!.checklist).firstOrNull;
    final detail = [
      formatDate(e.date),
      ?e.place,
      if (checklist != null && w!.itemsTotal != null)
        '${checklist.label} ${w.itemsDone} of ${w.itemsTotal}',
      if (w?.minutes case final m? when m > 0) '$m min',
      if (e.expense != null) 'from Expenses',
    ].join(' · ');
    final amount = w?.usedPass == true
        ? 'Pass'
        : e.amountCents > 0
        ? formatMoney(e.amountCents)
        : 'Free';
    return InkWell(
      onTap: () => e.expense != null
          ? context.push(AppRoutes.expense(e.expense!.id))
          : _confirmDelete(context, ref, w!),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _TypeBadge(type: e.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    style: AppText.cardTitle.copyWith(color: c.ink),
                  ),
                  Text(detail, style: AppText.sub.copyWith(color: c.muted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              amount,
              style: e.amountCents > 0
                  ? AppText.amount.copyWith(color: c.ink)
                  : AppText.label.copyWith(color: c.muted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// Delete a wash; a paid one asks whether its expense goes too.
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Wash w,
  ) async {
    final c = context.colors;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete this ${w.type.title.toLowerCase()}?'),
        content: Text(
          w.expenseId == null
              ? 'It comes off your wash history.'
              : 'It was also logged in Expenses as Car wash.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: c.muted)),
          ),
          if (w.expenseId != null)
            TextButton(
              onPressed: () => Navigator.pop(context, 'wash'),
              child: const Text('Keep the expense'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'both'),
            child: Text(
              w.expenseId == null ? 'Delete' : 'Delete both',
              style: TextStyle(color: c.warn),
            ),
          ),
        ],
      ),
    );
    if (choice == null) return;
    await ref
        .read(washActionsProvider)
        .delete(w, withExpense: choice == 'both');
    if (context.mounted) showAppSnackBar(context, 'Wash deleted');
  }
}

/// AUTO / DIY / HAND / DETAIL, or the car-wash icon for one from Expenses.
class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final WashType? type;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg, border, text) = switch (type) {
      WashType.automatic => (c.highlight, c.onHighlight, c.onHighlight, 'AUTO'),
      WashType.home => (c.tile, c.primaryText, null, 'DIY'),
      WashType.hand => (c.primary, c.onPrimary, null, 'HAND'),
      WashType.detail => (c.ink, c.background, null, 'DTL'),
      null => (c.tile, c.primaryText, null, null),
    };
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: border == null ? null : Border.all(color: border, width: 1.5),
      ),
      child: text == null
          ? Icon(ExpenseCategory.carWash.icon, size: 18, color: fg)
          : Text(text, style: AppText.tiny.copyWith(color: fg, fontSize: 10)),
    );
  }
}
