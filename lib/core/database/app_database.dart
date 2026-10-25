import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/expenses/domain/expense_category.dart';
import '../../features/expenses/domain/recurrence.dart';
import '../../features/vehicles/domain/body_type.dart';
import '../../features/vehicles/domain/fuel_type.dart';
import '../../features/vehicles/domain/vehicle_status.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Vehicles,
    OdometerReadings,
    ServiceSchedules,
    Expenses,
    RecurringExpenses,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The on-device database.
  AppDatabase.open() : super(driftDatabase(name: 'servobuddy'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // v2: recurring costs.
      if (from < 2) await m.createTable(recurringExpenses);
      // v3: sold / not in use, and delete-but-keep-history.
      if (from < 3) {
        await m.addColumn(vehicles, vehicles.status);
        await m.addColumn(vehicles, vehicles.soldDate);
        await m.addColumn(vehicles, vehicles.salePriceCents);
      }
    },
    // Deleting a car must take its expenses, readings and schedules with it.
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
