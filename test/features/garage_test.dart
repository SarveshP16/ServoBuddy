import 'package:flutter_test/flutter_test.dart';
import 'package:servobuddy/features/expenses/domain/expense_category.dart';
import 'package:servobuddy/features/garage/domain/garage.dart';
import 'package:servobuddy/features/reminders/domain/reminder_plan.dart';
import 'package:servobuddy/features/vehicles/domain/vehicle_alert.dart';

import '../support/builders.dart';

void main() {
  final today = DateTime(2026, 9, 23);

  Garage garageWith({
    DateTime? regoExpiry,
    int baselineKm = 33030,
    List<int> odometers = const [38000, 42180],
  }) => Garage(
    vehicles: [
      vehicle(regoExpiry: regoExpiry),
      vehicle(id: 2, make: 'Mazda', model: 'CX-5', isPrimary: false),
    ],
    readings: [
      reading(odometers[0], DateTime(2026, 6, 25)),
      reading(odometers[1], today, id: 2),
    ],
    schedules: [
      schedule(baselineKm: baselineKm, baselineDate: DateTime(2026, 3, 1)),
    ],
    expenses: [
      expense(id: 1, date: DateTime(2026, 9, 22)),
      expense(
        id: 2,
        vehicleId: 2,
        category: ExpenseCategory.rego,
        date: DateTime(2026, 9, 1),
      ),
    ],
    today: today,
  );

  test('derives odometer, pace and the most urgent service', () {
    final g = garageWith();
    expect(g.primary!.model, 'Corolla');
    expect(g.odometerOf(1), 42180);
    expect(g.kmPerDayOf(1), closeTo(4180 / 90, 0.01));
    final next = g.mostUrgentDue!;
    expect(next.vehicle.id, 1);
    expect(next.due.kmLeft, 850);
    expect(g.nextDueFor(2), isNull);
  });

  test('alerts: overdue service beats rego due soon', () {
    expect(
      garageWith(
        baselineKm: 30000,
        regoExpiry: DateTime(2026, 10, 1),
      ).alertOf(garageWith().vehicles.first),
      VehicleAlert.serviceOverdue,
    );
    final g = garageWith(baselineKm: 40000, regoExpiry: DateTime(2026, 10, 1));
    expect(g.alertOf(g.vehicles.first), VehicleAlert.regoDueSoon);
  });

  test('reminder plan: rego 2 weeks before and on the day, at 9am', () {
    final g = garageWith(baselineKm: 40000, regoExpiry: DateTime(2026, 12, 1));
    final plan = planReminders(g, DateTime(2026, 9, 23, 12));
    final rego = plan.where((p) => p.title.startsWith('Rego')).toList();
    expect(rego.map((p) => p.at), [
      DateTime(2026, 11, 17, 9),
      DateTime(2026, 12, 1, 9),
    ]);
    expect(rego.first.title, 'Rego due in 2 weeks — Toyota Corolla');
    // Ids are unique and times ascending.
    expect(plan.map((p) => p.id).toSet().length, plan.length);
    for (var i = 1; i < plan.length; i++) {
      expect(plan[i].at.isBefore(plan[i - 1].at), isFalse);
    }
  });

  test('reminder plan skips anything already in the past', () {
    final g = garageWith(regoExpiry: DateTime(2026, 9, 30));
    final plan = planReminders(g, DateTime(2026, 9, 23, 12));
    final rego = plan.where((p) => p.title.startsWith('Rego')).toList();
    expect(rego.map((p) => p.at), [DateTime(2026, 9, 30, 9)]);
  });
}
