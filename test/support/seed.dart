import 'package:drift/drift.dart';
import 'package:servobuddy/core/database/app_database.dart';
import 'package:servobuddy/features/expenses/domain/expense_category.dart';
import 'package:servobuddy/features/vehicles/domain/body_type.dart';
import 'package:servobuddy/features/vehicles/domain/fuel_type.dart';

/// The mockups' garage: a Corolla (oil change due in 850 km), a CX-5 and an
/// overdue Ranger, with this year's Corolla spend adding up to $640.
Future<void> seedMockupGarage(AppDatabase db) async {
  Future<int> car(
    String make,
    String model,
    int year,
    int km, {
    bool primary = false,
    String? rego,
    DateTime? created,
  }) async {
    final id = await db
        .into(db.vehicles)
        .insert(
          VehiclesCompanion.insert(
            make: make,
            model: model,
            year: year,
            bodyType: BodyType.sedan,
            fuelType: FuelType.e10,
            rego: Value(rego),
            isPrimary: Value(primary),
            createdAt: created ?? DateTime(2026, 1, 1),
          ),
        );
    await db
        .into(db.odometerReadings)
        .insert(
          OdometerReadingsCompanion.insert(
            vehicleId: id,
            date: DateTime(2026, 9, 23),
            km: km,
          ),
        );
    return id;
  }

  final corolla = await car(
    'Toyota',
    'Corolla',
    2019,
    42180,
    primary: true,
    rego: '7XY-2KL',
  );
  await car('Mazda', 'CX-5', 2021, 18940, created: DateTime(2026, 1, 2));
  final ranger = await car(
    'Ford',
    'Ranger',
    2017,
    88410,
    created: DateTime(2026, 1, 3),
  );

  // Corolla's pace: 4,180 km over 90 days (~46 km/day).
  await db
      .into(db.odometerReadings)
      .insert(
        OdometerReadingsCompanion.insert(
          vehicleId: corolla,
          date: DateTime(2026, 6, 25),
          km: 38000,
        ),
      );

  await db
      .into(db.serviceSchedules)
      .insert(
        ServiceSchedulesCompanion.insert(
          vehicleId: corolla,
          name: 'Oil change',
          intervalKm: const Value(10000),
          intervalMonths: const Value(12),
          baselineKm: const Value(33030),
          baselineDate: Value(DateTime(2026, 3, 1)),
        ),
      );
  await db
      .into(db.serviceSchedules)
      .insert(
        ServiceSchedulesCompanion.insert(
          vehicleId: ranger,
          name: 'Logbook service',
          intervalKm: const Value(15000),
          intervalMonths: const Value(12),
          baselineKm: const Value(70000),
          baselineDate: Value(DateTime(2025, 6, 1)),
        ),
      );

  Future<void> spend(
    ExpenseCategory category,
    int cents,
    DateTime date, {
    String? title,
    double? litres,
  }) => db
      .into(db.expenses)
      .insert(
        ExpensesCompanion.insert(
          vehicleId: corolla,
          category: category,
          amountCents: cents,
          date: date,
          title: Value(title),
          litres: Value(litres),
        ),
      );

  await spend(ExpenseCategory.fuel, 34160, DateTime(2026, 7, 1));
  await spend(ExpenseCategory.fuel, 6840, DateTime(2026, 9, 22), litres: 42.2);
  await spend(
    ExpenseCategory.service,
    22000,
    DateTime(2026, 6, 12),
    title: 'Logbook service',
  );
  await spend(
    ExpenseCategory.service,
    6000,
    DateTime(2026, 3, 2),
    title: 'Tyre rotation',
  );
  await spend(ExpenseCategory.rego, 5000, DateTime(2026, 2, 1));
}
