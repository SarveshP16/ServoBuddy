import 'package:flutter_test/flutter_test.dart';
import 'package:servobuddy/features/expenses/domain/expense_category.dart';
import 'package:servobuddy/features/service/domain/service_due.dart';
import 'package:servobuddy/features/service/presentation/due_text.dart';
import 'package:servobuddy/features/vehicles/domain/odometer.dart';

import '../support/builders.dart';

void main() {
  final today = DateTime(2026, 9, 23);

  group('kmPerDay', () {
    test('averages the rise across the window', () {
      final pace = kmPerDay([
        OdometerSample(DateTime(2026, 6, 25), 38000),
        OdometerSample(DateTime(2026, 9, 23), 42180),
      ], today);
      expect(pace, closeTo(4180 / 90, 0.001));
    });

    test('is unknown with one reading or too short a span', () {
      expect(kmPerDay([OdometerSample(today, 100)], today), isNull);
      expect(
        kmPerDay([
          OdometerSample(DateTime(2026, 9, 20), 100),
          OdometerSample(today, 400),
        ], today),
        isNull,
      );
    });

    test('current odometer is the highest reading', () {
      expect(
        currentOdometer([
          OdometerSample(DateTime(2026, 9, 1), 42180),
          OdometerSample(DateTime(2026, 8, 1), 43000),
        ]),
        43000,
      );
    });
  });

  group('computeServiceDue', () {
    test("matches the mockup: oil change in 850 km, ~3 weeks", () {
      final due = computeServiceDue(
        schedule: schedule(
          baselineKm: 33030,
          baselineDate: DateTime(2026, 3, 1),
        ),
        records: const [],
        currentKm: 42180,
        kmPerDay: 40,
        today: today,
      );
      expect(due.kmLeft, 850);
      expect(due.estimatedDaysLeft, 22); // 850 / 40 rounded up.
      expect(due.status, DueStatus.soon);
      expect(dueDetail(due), 'in 850 km · ~3 weeks');
      expect(dueHeadline(due), 'Oil change due');
    });

    test('the date limit wins when it comes first', () {
      final due = computeServiceDue(
        schedule: schedule(
          baselineKm: 40000,
          baselineDate: DateTime(2025, 10, 1),
        ),
        records: const [],
        currentKm: 42180,
        kmPerDay: 20,
        today: today,
      );
      expect(due.dueDate, DateTime(2026, 10, 1));
      expect(due.daysLeftByDate, 8);
      expect(due.dateBound, isTrue);
      expect(dueDetail(due), 'in 7,820 km · 8 days');
    });

    test('a later service record resets the clock', () {
      final due = computeServiceDue(
        schedule: schedule(
          baselineKm: 30000,
          baselineDate: DateTime(2025, 1, 1),
        ),
        records: [
          expense(
            category: ExpenseCategory.service,
            date: DateTime(2026, 9, 1),
            odometerKm: 41500,
            scheduleId: 1,
          ),
          // Another schedule's record is ignored.
          expense(
            id: 2,
            category: ExpenseCategory.service,
            date: DateTime(2026, 9, 10),
            odometerKm: 42000,
            scheduleId: 99,
          ),
        ],
        currentKm: 42180,
        kmPerDay: null,
        today: today,
      );
      expect(due.lastKm, 41500);
      expect(due.dueKm, 51500);
      expect(due.dueDate, DateTime(2027, 9, 1));
      expect(due.status, DueStatus.ok);
    });

    test('overdue by km', () {
      final due = computeServiceDue(
        schedule: schedule(
          baselineKm: 30000,
          baselineDate: DateTime(2026, 6, 1),
        ),
        records: const [],
        currentKm: 40120,
        kmPerDay: null,
        today: today,
      );
      expect(due.status, DueStatus.overdue);
      expect(dueHeadline(due), 'Oil change overdue');
      expect(dueDetail(due), 'by 120 km');
      expect(dueStatValue(due), 'Overdue');
    });

    test('unknown without any last-done', () {
      final due = computeServiceDue(
        schedule: schedule(),
        records: const [],
        currentKm: 42180,
        kmPerDay: 30,
        today: today,
      );
      expect(due.status, DueStatus.unknown);
    });

    test('urgency order: overdue, then soonest', () {
      ServiceDue make(int baselineKm, int id) => computeServiceDue(
        schedule: schedule(
          id: id,
          baselineKm: baselineKm,
          intervalMonths: null,
        ),
        records: const [],
        currentKm: 42180,
        kmPerDay: 40,
        today: today,
      );
      final list = [make(40000, 1), make(32000, 2), make(33000, 3)]
        ..sort(compareUrgency);
      expect(list.map((d) => d.schedule.id), [2, 3, 1]);
    });
  });
}
