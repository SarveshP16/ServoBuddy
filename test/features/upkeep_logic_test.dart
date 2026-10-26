import 'package:flutter_test/flutter_test.dart';
import 'package:servobuddy/features/expenses/domain/expense_category.dart';
import 'package:servobuddy/features/garage/domain/garage.dart';
import 'package:servobuddy/features/home_widget/domain/widget_snapshot.dart';
import 'package:servobuddy/features/reminders/domain/reminder_plan.dart';
import 'package:servobuddy/features/reminders/domain/rego_renewal.dart';
import 'package:servobuddy/features/reminders/presentation/upcoming_items.dart';
import 'package:servobuddy/features/vehicles/domain/wear_parts.dart';

import '../support/builders.dart';

void main() {
  final today = DateTime(2026, 10, 27);

  group('rego renewal checklist', () {
    test('only shows from six weeks out', () {
      expect(
        regoRenewalFor(vehicle(regoExpiry: DateTime(2026, 12, 9)), [], today),
        isNull,
      );
      expect(
        regoRenewalFor(vehicle(regoExpiry: DateTime(2026, 12, 8)), [], today),
        isNotNull,
      );
      expect(regoRenewalFor(vehicle(), [], today), isNull); // No rego date.
    });

    test('pink slip only for cars five or more years old', () {
      final due = DateTime(2026, 11, 20);
      List<RenewalStep> steps(int year) => regoRenewalFor(
        vehicle(year: year, regoExpiry: due),
        [],
        today,
      )!.steps.map((s) => s.step).toList();
      expect(steps(2019), RenewalStep.values);
      expect(steps(2024), [RenewalStep.greenSlip, RenewalStep.payRego]);
    });

    test('steps are ticked by Rego expenses with their title', () {
      final r = regoRenewalFor(
        vehicle(year: 2019, regoExpiry: DateTime(2026, 11, 20)),
        [
          expense(
            category: ExpenseCategory.rego,
            title: 'CTP green slip',
            date: DateTime(2026, 10, 20),
          ),
          // Last year's pink slip doesn't count for this year.
          expense(
            id: 2,
            category: ExpenseCategory.rego,
            title: 'Pink slip inspection',
            date: DateTime(2025, 11, 1),
          ),
          // Nor does a title on the wrong category.
          expense(id: 3, title: 'Rego renewal', date: DateTime(2026, 10, 25)),
        ],
        today,
      )!;
      expect(r.doneCount, 1);
      expect(r.steps.first.done?.id, 1);
    });
  });

  group('tyre and battery age', () {
    test('battery: replace at four years, flagged in the last 90 days', () {
      final age = partAgeFor(
        vehicle(batteryFitted: DateTime(2023, 1, 15)),
        WearPart.battery,
        today: today,
      )!;
      expect(age.replaceBy, DateTime(2027, 1, 15));
      expect(age.status, WearStatus.soon);
      expect(
        partAgeFor(
          vehicle(batteryFitted: DateTime(2022, 6, 1)),
          WearPart.battery,
          today: today,
        )!.status,
        WearStatus.due,
      );
    });

    test('tyres: five years, or 40,000 km if that comes first', () {
      final v = vehicle(
        tyresFitted: DateTime(2025, 1, 1),
        tyresFittedKm: 20000,
      );
      // 30,000 km on, at 50 km a day the last 10,000 km take 200 days.
      final age = partAgeFor(
        v,
        WearPart.tyres,
        today: today,
        currentKm: 50000,
        kmPerDay: 50,
      )!;
      expect(age.replaceAtKm, 60000);
      expect(age.replaceBy, DateTime(2027, 5, 15));
      expect(age.status, WearStatus.ok);
      // Past the distance: due whatever the date.
      expect(
        partAgeFor(v, WearPart.tyres, today: today, currentKm: 60500)!.status,
        WearStatus.due,
      );
      // Without the km at fitting, only age counts.
      expect(
        partAgeFor(
          vehicle(tyresFitted: DateTime(2025, 1, 1)),
          WearPart.tyres,
          today: today,
          currentKm: 90000,
        )!.replaceBy,
        DateTime(2030, 1, 1),
      );
      expect(partAgeFor(vehicle(), WearPart.tyres, today: today), isNull);
    });

    test('ages read naturally', () {
      expect(formatAge(DateTime(2024, 3, 1), today), '2 yrs 7 mths');
      expect(formatAge(DateTime(2025, 10, 27), today), '1 yr');
      expect(formatAge(DateTime(2026, 10, 1), today), '3 weeks');
      expect(formatAge(DateTime(2026, 10, 26), today), '1 day');
    });

    test('an old battery shows in Coming up and gets reminders', () {
      final garage = Garage(
        vehicles: [vehicle(batteryFitted: DateTime(2023, 1, 15))],
        readings: const [],
        schedules: const [],
        expenses: const [],
        today: today,
      );
      expect(
        upcomingItems(garage).map((i) => i.kind),
        contains(UpcomingKind.battery),
      );
      final plan = planReminders(garage, today);
      expect(
        plan.map((n) => n.title),
        contains('Battery due for replacing — Toyota Corolla'),
      );
    });
  });

  group('home screen widget', () {
    test('shows the most pressing item and this month’s spend', () {
      final garage = Garage(
        vehicles: [vehicle(regoExpiry: DateTime(2026, 11, 5))],
        readings: const [],
        schedules: const [],
        expenses: [
          expense(amountCents: 5000, date: DateTime(2026, 10, 3)),
          expense(id: 2, amountCents: 2500, date: DateTime(2026, 10, 20)),
          expense(id: 3, amountCents: 9999, date: DateTime(2026, 9, 30)),
        ],
        today: today,
      );
      final s = widgetSnapshot(garage);
      expect(s.dueTitle, 'Rego renewal — Corolla');
      expect(s.vehicleId, 1);
      expect(s.monthSpend, r'$75');
    });

    test('nothing set up yet', () {
      final s = widgetSnapshot(
        Garage(
          vehicles: [vehicle()],
          readings: const [],
          schedules: const [],
          expenses: const [],
          today: today,
        ),
      );
      expect(s.dueTitle, 'Nothing due');
      expect(s.vehicleId, isNull);
      expect(s.monthSpend, r'$0');
    });
  });
}
