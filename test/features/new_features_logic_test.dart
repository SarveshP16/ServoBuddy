import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servobuddy/core/database/app_database.dart';
import 'package:servobuddy/features/expenses/domain/expense_category.dart';
import 'package:servobuddy/features/expenses/domain/recurrence.dart';
import 'package:servobuddy/features/garage/domain/garage.dart';
import 'package:servobuddy/features/reminders/domain/nsw_slips.dart';
import 'package:servobuddy/features/reminders/domain/reminder_plan.dart';
import 'package:servobuddy/features/vehicles/domain/vehicle_status.dart';

import '../support/builders.dart';

void main() {
  group('recurrence', () {
    test('monthly from the 31st returns to the 31st instead of drifting', () {
      final start = DateTime(2026, 1, 31);
      expect(
        [
          for (var n = 0; n < 4; n++)
            occurrence(start, RecurFrequency.monthly, n),
        ],
        [
          DateTime(2026, 1, 31),
          DateTime(2026, 2, 28),
          DateTime(2026, 3, 31),
          DateTime(2026, 4, 30),
        ],
      );
    });

    test('fortnightly and yearly', () {
      final start = DateTime(2026, 9, 1);
      expect(
        occurrence(start, RecurFrequency.fortnightly, 2),
        DateTime(2026, 9, 29),
      );
      expect(
        occurrence(DateTime(2024, 2, 29), RecurFrequency.yearly, 1),
        DateTime(2025, 2, 28),
      );
    });

    test('pending: everything due by today that is not yet handled', () {
      final due = pendingOccurrences(
        start: DateTime(2026, 7, 1),
        frequency: RecurFrequency.monthly,
        handled: 1,
        today: DateTime(2026, 9, 23, 15),
      );
      expect(due, [DateTime(2026, 8, 1), DateTime(2026, 9, 1)]);
      expect(
        pendingOccurrences(
          start: DateTime(2026, 10, 1),
          frequency: RecurFrequency.monthly,
          handled: 0,
          today: DateTime(2026, 9, 23),
        ),
        isEmpty,
      );
    });
  });

  group('NSW green and pink slips', () {
    final today = DateTime(2026, 9, 23);

    test('pink slip only for cars five or more years old', () {
      expect(needsPinkSlip(2021, today), isTrue);
      expect(needsPinkSlip(2022, today), isFalse);
    });

    test('both follow the rego date', () {
      final slips = nswSlipsFor(
        vehicle(regoExpiry: DateTime(2026, 12, 1)),
        today,
      )!;
      expect(slips.greenSlipBy, DateTime(2026, 12, 1));
      expect(slips.greenSlipReminder, DateTime(2026, 11, 10));
      expect(slips.pinkSlipFrom, DateTime(2026, 10, 20));
      expect(nswSlipsFor(vehicle(), today), isNull); // No rego date.
    });

    test('reminders are scheduled at 9 am', () {
      final g = Garage(
        vehicles: [vehicle(regoExpiry: DateTime(2026, 12, 1))],
        readings: const [],
        schedules: const [],
        expenses: const [],
        today: today,
      );
      final plan = planReminders(g, DateTime(2026, 9, 23, 12));
      final green = plan.singleWhere((p) => p.title.contains('green slip'));
      final pink = plan.singleWhere((p) => p.title.contains('Pink slip'));
      expect(green.at, DateTime(2026, 11, 10, 9));
      expect(pink.at, DateTime(2026, 10, 20, 9));
    });
  });

  test('recurring cost reminder: next due date only, not when paused', () {
    RecurringExpense item({bool paused = false}) => RecurringExpense(
      id: 1,
      vehicleId: 1,
      category: ExpenseCategory.insurance,
      amountCents: 12000,
      title: 'Car insurance',
      frequency: RecurFrequency.monthly,
      startDate: DateTime(2026, 7, 1),
      handledCount: 3,
      paused: paused,
    );
    Garage g(RecurringExpense r) => Garage(
      vehicles: [vehicle()],
      readings: const [],
      schedules: const [],
      expenses: const [],
      recurring: [r],
      today: DateTime(2026, 9, 23),
    );
    final plan = planReminders(g(item()), DateTime(2026, 9, 23, 12));
    final r = plan.singleWhere((p) => p.title.startsWith('Car insurance'));
    expect(r.at, DateTime(2026, 10, 1, 9));
    expect(r.body, contains(r'$120'));
    expect(
      planReminders(g(item(paused: true)), DateTime(2026, 9, 23, 12)),
      isEmpty,
    );
  });

  group('database upgrades', () {
    /// Today's schema rolled back to [version]: v3 added the vehicle status
    /// columns, v2 the recurring-costs table.
    Future<List<String>> schemaAt(int version) async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final fresh = AppDatabase(NativeDatabase.memory());
      final ddl = await fresh
          .customSelect(
            "SELECT name, sql FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%'",
          )
          .map((r) => (r.read<String>('name'), r.read<String>('sql')))
          .get();
      await fresh.close();
      return [
        for (final (name, sql) in ddl)
          if (!(version < 2 && name == 'recurring_expenses'))
            name == 'vehicles' && version < 3
                ? sql.replaceAll(
                    RegExp(r',\s*"(status|sold_date|sale_price_cents)"[^,)]*'),
                    '',
                  )
                : sql,
      ];
    }

    Future<AppDatabase> openOld(int version) async {
      final ddl = await schemaAt(version);
      expect(
        ddl.firstWhere((s) => s.contains('"vehicles"')),
        isNot(contains('status')),
      );
      return AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            for (final statement in ddl) {
              raw.execute(statement);
            }
            raw.execute(
              "INSERT INTO vehicles (make, model, year, body_type, fuel_type, "
              "is_primary, created_at) VALUES ('Toyota', 'Corolla', 2019, "
              "'sedan', 'e10', 1, 0)",
            );
            raw.execute('PRAGMA user_version = $version');
          },
        ),
      );
    }

    for (final version in [1, 2]) {
      test('v$version to v3 keeps cars, which come back as in use', () async {
        final db = await openOld(version);
        final car = (await db.select(db.vehicles).get()).single;
        expect(car.model, 'Corolla');
        expect(car.status, VehicleStatus.active);
        expect(car.soldDate, isNull);
        // v2's table exists either way.
        await db
            .into(db.recurringExpenses)
            .insert(
              RecurringExpensesCompanion.insert(
                vehicleId: car.id,
                category: ExpenseCategory.tolls,
                amountCents: 4000,
                frequency: RecurFrequency.monthly,
                startDate: DateTime(2026, 10, 1),
              ),
            );
        expect(await db.select(db.recurringExpenses).get(), hasLength(1));
        await db.close();
      });
    }
  });
}
