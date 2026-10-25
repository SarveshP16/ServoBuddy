import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/garage.dart';

class GarageRepository {
  GarageRepository(this._db, this._now);

  final AppDatabase _db;
  final DateTime Function() _now;

  Future<Garage> load() async {
    final results = await Future.wait<List<Object>>([
      _db.select(_db.vehicles).get(),
      _db.select(_db.odometerReadings).get(),
      _db.select(_db.serviceSchedules).get(),
      _db.select(_db.expenses).get(),
      _db.select(_db.recurringExpenses).get(),
    ]);
    return Garage(
      vehicles: results[0].cast<Vehicle>(),
      readings: results[1].cast<OdometerReading>(),
      schedules: results[2].cast<ServiceSchedule>(),
      expenses: results[3].cast<Expense>(),
      recurring: results[4].cast<RecurringExpense>(),
      today: _now(),
    );
  }

  /// A fresh snapshot now, and again after every write to any table.
  Stream<Garage> watch() async* {
    yield await load();
    await for (final _ in _db.tableUpdates(
      TableUpdateQuery.onAllTables([
        _db.vehicles,
        _db.odometerReadings,
        _db.serviceSchedules,
        _db.expenses,
        _db.recurringExpenses,
      ]),
    )) {
      yield await load();
    }
  }
}
