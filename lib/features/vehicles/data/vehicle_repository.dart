import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/calendar.dart';
import '../domain/vehicle_status.dart';

class VehicleRepository {
  VehicleRepository(this._db);

  final AppDatabase _db;

  /// Adds a car with its starting odometer reading. The first car added
  /// becomes the primary one.
  Future<int> create(
    VehiclesCompanion vehicle, {
    required int odometerKm,
    required DateTime today,
  }) => _db.transaction(() async {
    final existing = await _db.select(_db.vehicles).get();
    final id = await _db
        .into(_db.vehicles)
        .insert(
          vehicle.copyWith(
            isPrimary: Value(existing.isEmpty),
            createdAt: Value(today),
          ),
        );
    await recordOdometer(id, odometerKm, today);
    return id;
  });

  Future<void> save(Vehicle vehicle) =>
      _db.update(_db.vehicles).replace(vehicle);

  Future<void> delete(int id) =>
      (_db.delete(_db.vehicles)..where((v) => v.id.equals(id))).go();

  /// Makes [id] the primary car; if the primary car was deleted, promotes the
  /// oldest remaining one.
  Future<void> setPrimary(int id) => _db.transaction(() async {
    await _db
        .update(_db.vehicles)
        .write(const VehiclesCompanion(isPrimary: Value(false)));
    await (_db.update(_db.vehicles)..where((v) => v.id.equals(id))).write(
      const VehiclesCompanion(isPrimary: Value(true)),
    );
  });

  /// Makes sure one car *in use* is primary, promoting the oldest if needed.
  Future<void> ensurePrimary() async {
    final active =
        await (_db.select(_db.vehicles)
              ..where((v) => v.status.equalsValue(VehicleStatus.active))
              ..orderBy([(v) => OrderingTerm(expression: v.createdAt)]))
            .get();
    if (active.isNotEmpty && !active.any((v) => v.isPrimary)) {
      await setPrimary(active.first.id);
    }
  }

  /// Sold / not in use (or back in use with [VehicleStatus.active]). A car
  /// leaving service hands "primary" on to another.
  Future<void> setStatus(
    int id,
    VehicleStatus status, {
    DateTime? soldDate,
    int? salePriceCents,
  }) => _db.transaction(() async {
    await (_db.update(_db.vehicles)..where((v) => v.id.equals(id))).write(
      VehiclesCompanion(
        status: Value(status),
        soldDate: Value(soldDate),
        salePriceCents: Value(salePriceCents),
        isPrimary: status == VehicleStatus.active
            ? const Value.absent()
            : const Value(false),
      ),
    );
    await ensurePrimary();
  });

  /// Deletes the car but keeps its expenses (and so its name on them).
  /// Everything that only matters for a car in use goes.
  Future<void> deleteKeepingHistory(int id) => _db.transaction(() async {
    await (_db.delete(
      _db.serviceSchedules,
    )..where((s) => s.vehicleId.equals(id))).go();
    await (_db.delete(
      _db.odometerReadings,
    )..where((r) => r.vehicleId.equals(id))).go();
    await (_db.delete(
      _db.recurringExpenses,
    )..where((r) => r.vehicleId.equals(id))).go();
    await (_db.update(_db.vehicles)..where((v) => v.id.equals(id))).write(
      const VehiclesCompanion(
        status: Value(VehicleStatus.deleted),
        isPrimary: Value(false),
        photoPath: Value(null),
      ),
    );
    await ensurePrimary();
  });

  /// A typed-in odometer reading. Replaces any other typed-in reading on the
  /// same day so editing a car twice doesn't leave two points.
  Future<void> recordOdometer(int vehicleId, int km, DateTime date) async {
    final day = dateOnly(date);
    await (_db.delete(
      _db.odometerReadings,
    )..where((r) => r.vehicleId.equals(vehicleId) & r.date.equals(day))).go();
    await _db
        .into(_db.odometerReadings)
        .insert(
          OdometerReadingsCompanion.insert(
            vehicleId: vehicleId,
            date: day,
            km: km,
          ),
        );
  }
}
