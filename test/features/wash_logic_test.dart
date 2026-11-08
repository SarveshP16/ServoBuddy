import 'package:flutter_test/flutter_test.dart';
import 'package:servobuddy/features/expenses/domain/expense_category.dart';
import 'package:servobuddy/features/garage/domain/garage.dart';
import 'package:servobuddy/features/reminders/domain/reminder_plan.dart';
import 'package:servobuddy/features/reminders/presentation/upcoming_items.dart';
import 'package:servobuddy/features/wash/application/wash_actions.dart';
import 'package:servobuddy/features/wash/domain/wash_checklist.dart';
import 'package:servobuddy/features/wash/domain/wash_history.dart';
import 'package:servobuddy/features/wash/domain/wash_type.dart';

import '../support/builders.dart';

void main() {
  final today = DateTime(2026, 11, 9);

  Garage garageWith({
    List washes = const [],
    List expenses = const [],
    int? washEveryDays,
  }) => Garage(
    vehicles: [vehicle(washEveryDays: washEveryDays)],
    readings: const [],
    schedules: const [],
    expenses: expenses.cast(),
    washes: washes.cast(),
    today: today,
  );

  test('history: washes, plus Car wash expenses with no wash behind them', () {
    final g = garageWith(
      washes: [
        wash(
          date: DateTime(2026, 10, 28),
          place: 'Westside',
          amountCents: 1800,
          expenseId: 7,
        ),
        wash(id: 2, date: DateTime(2026, 10, 12), type: WashType.home),
      ],
      expenses: [
        // Logged by the wash above: not shown twice.
        expense(
          id: 7,
          category: ExpenseCategory.carWash,
          amountCents: 1800,
          date: DateTime(2026, 10, 28),
        ),
        // Logged straight in Expenses.
        expense(
          id: 8,
          category: ExpenseCategory.carWash,
          amountCents: 3500,
          date: DateTime(2026, 9, 21),
          title: 'Hand wash',
        ),
        expense(id: 9, date: DateTime(2026, 9, 20)), // Fuel.
      ],
    );
    final h = washHistory(g, 1);
    expect(h.map((e) => e.title), [
      'Automatic wash',
      'Wash at home',
      'Hand wash',
    ]);
    expect(h.last.type, isNull);
    expect(h.last.expense?.id, 8);
  });

  test('stats: count, spend, usual gap and mix for this year', () {
    final h = washHistory(
      garageWith(
        washes: [
          wash(date: DateTime(2026, 11, 1), amountCents: 1800),
          wash(id: 2, date: DateTime(2026, 10, 11), type: WashType.home),
          wash(
            id: 3,
            date: DateTime(2026, 9, 20),
            type: WashType.hand,
            amountCents: 3500,
          ),
          wash(id: 4, date: DateTime(2025, 6, 1), amountCents: 1800),
        ],
      ),
      1,
    );
    final s = washStats(h, today);
    expect(s.countThisYear, 3);
    expect(s.spendThisYear, 5300);
    expect(s.averageGapDays, 21); // 42 days over two gaps.
    expect(s.byType, {
      WashType.home: 1,
      WashType.automatic: 1,
      WashType.hand: 1,
    });
    expect(s.last?.date, DateTime(2026, 11, 1));
  });

  test('remembered places: latest price, each place once, paid only', () {
    final places = rememberedPlaces(
      garageWith(
        washes: [
          wash(
            date: DateTime(2026, 11, 1),
            place: 'Westside',
            amountCents: 2000,
          ),
          wash(
            id: 2,
            date: DateTime(2026, 10, 1),
            place: 'westside ',
            amountCents: 1800,
          ),
          wash(
            id: 3,
            date: DateTime(2026, 9, 1),
            place: 'Shine Bros',
            type: WashType.hand,
            amountCents: 3500,
          ),
          wash(
            id: 4,
            date: DateTime(2026, 8, 1),
            place: 'Driveway',
            type: WashType.home,
          ),
        ],
      ),
    );
    expect(places.map((p) => (p.place, p.amountCents)), [
      ('Westside', 2000),
      ('Shine Bros', 3500),
    ]);
  });

  test('wash reminder: due a set gap after the last wash', () {
    final g = garageWith(
      washes: [wash(date: DateTime(2026, 10, 15))],
      washEveryDays: 21,
    );
    expect(
      nextWashDue(g.vehicles.single, washHistory(g, 1), today),
      DateTime(2026, 11, 5),
    );
    final item = upcomingItems(g)
        .singleWhere((i) => i.kind == UpcomingKind.wash);
    expect(item.title, 'Wash overdue');
    expect(item.urgent, isFalse);
    // Off: nothing listed, nothing scheduled.
    final off = garageWith(washes: [wash(date: DateTime(2026, 10, 15))]);
    expect(
      upcomingItems(off).where((i) => i.kind == UpcomingKind.wash),
      isEmpty,
    );
    expect(
      planReminders(
        garageWith(
          washes: [wash(date: DateTime(2026, 11, 1))],
          washEveryDays: 14,
        ),
        today,
      ).map((n) => n.title),
      contains('Time for a wash — Toyota Corolla'),
    );
  });

  test('checklists round-trip through settings, and bad data is ignored', () {
    final items = defaultChecklists[ChecklistKind.full]!;
    expect(decodeChecklist(encodeChecklist(items)), items);
    expect(decodeChecklist('not json'), isNull);
    expect(decodeChecklist(null), isNull);
    // Each checklist builds on the last.
    expect(
      defaultChecklists[ChecklistKind.detail]!,
      containsAll(defaultChecklists[ChecklistKind.full]!),
    );
  });
}
