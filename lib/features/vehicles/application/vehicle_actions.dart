import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers.dart';
import '../../../core/utils/calendar.dart';
import '../../garage/application/garage_provider.dart';
import '../domain/body_type.dart';
import '../domain/fuel_type.dart';
import '../domain/vehicle_status.dart';
import '../domain/wear_parts.dart';

/// What the vehicle form collects.
class VehicleDraft {
  const VehicleDraft({
    required this.make,
    required this.model,
    required this.year,
    required this.bodyType,
    required this.fuelType,
    required this.rego,
    required this.odometerKm,
    required this.photoPath,
    required this.regoExpiry,
    required this.insuranceExpiry,
  });

  final String make;
  final String model;
  final int year;
  final BodyType bodyType;
  final FuelType fuelType;
  final String? rego;
  final int odometerKm;

  /// A stored photo, or a just-picked temp file to import.
  final String? photoPath;
  final DateTime? regoExpiry;
  final DateTime? insuranceExpiry;
}

final vehicleActionsProvider = Provider<VehicleActions>(VehicleActions.new);

/// Vehicle writes that involve more than one store (database + photo files).
class VehicleActions {
  VehicleActions(this._ref);

  final Ref _ref;

  Future<int> create(VehicleDraft d) async {
    final photo = d.photoPath == null
        ? null
        : await _ref
              .read(imageStoreProvider)
              .import(d.photoPath!, folder: 'vehicles');
    return _ref
        .read(vehicleRepositoryProvider)
        .create(
          VehiclesCompanion.insert(
            make: d.make,
            model: d.model,
            year: d.year,
            bodyType: d.bodyType,
            fuelType: d.fuelType,
            rego: Value(d.rego),
            photoPath: Value(photo),
            regoExpiry: Value(d.regoExpiry),
            insuranceExpiry: Value(d.insuranceExpiry),
            createdAt: _ref.read(clockProvider)(),
          ),
          odometerKm: d.odometerKm,
          today: _ref.read(clockProvider)(),
        );
  }

  Future<void> update(Vehicle original, VehicleDraft d) async {
    final images = _ref.read(imageStoreProvider);
    var photo = original.photoPath;
    if (d.photoPath != original.photoPath) {
      photo = d.photoPath == null
          ? null
          : await images.import(d.photoPath!, folder: 'vehicles');
      await images.delete(original.photoPath);
    }
    final repo = _ref.read(vehicleRepositoryProvider);
    await repo.save(
      original.copyWith(
        make: d.make,
        model: d.model,
        year: d.year,
        bodyType: d.bodyType,
        fuelType: d.fuelType,
        rego: Value(d.rego),
        photoPath: Value(photo),
        regoExpiry: Value(d.regoExpiry),
        insuranceExpiry: Value(d.insuranceExpiry),
      ),
    );
    // Only a changed reading becomes a new data point, so opening and saving
    // the form doesn't distort the km-per-day estimate.
    if (d.odometerKm != _ref.read(garageProvider).odometerOf(original.id)) {
      await repo.recordOdometer(
        original.id,
        d.odometerKm,
        _ref.read(clockProvider)(),
      );
    }
  }

  /// Sold / not in use: drops out of lists and reminders, history kept.
  Future<void> retire(Vehicle v, {DateTime? soldDate, int? salePriceCents}) =>
      _ref
          .read(vehicleRepositoryProvider)
          .setStatus(
            v.id,
            VehicleStatus.retired,
            soldDate: soldDate,
            salePriceCents: salePriceCents,
          );

  /// Back in use: reminders and recurring costs resume.
  Future<void> restore(Vehicle v) => _ref
      .read(vehicleRepositoryProvider)
      .setStatus(v.id, VehicleStatus.active);

  /// Deletes the car but keeps its expenses (with their receipts) in the
  /// Expenses tab and totals. Only the car's photo is removed.
  Future<void> deleteKeepingHistory(Vehicle v) async {
    await _ref.read(vehicleRepositoryProvider).deleteKeepingHistory(v.id);
    await _ref.read(imageStoreProvider).delete(v.photoPath);
  }

  /// Deletes the car, everything logged against it, and their photos.
  Future<void> delete(Vehicle v) async {
    final garage = _ref.read(garageProvider);
    final images = _ref.read(imageStoreProvider);
    final files = [
      v.photoPath,
      for (final e in garage.expensesFor(v.id)) e.receiptPath,
    ];
    final repo = _ref.read(vehicleRepositoryProvider);
    await repo.delete(v.id);
    await repo.ensurePrimary();
    for (final f in files) {
      await images.delete(f);
    }
  }

  Future<void> setPrimary(int id) =>
      _ref.read(vehicleRepositoryProvider).setPrimary(id);

  /// Rego paid: moves the expiry on a year. Returns the new date, or null
  /// if the car has no rego date to move.
  Future<DateTime?> renewRego(int vehicleId) async {
    final v = _ref.read(garageProvider).vehicle(vehicleId);
    final expiry = v?.regoExpiry;
    if (v == null || expiry == null) return null;
    final next = addMonths(expiry, 12);
    await _ref
        .read(vehicleRepositoryProvider)
        .save(v.copyWith(regoExpiry: Value(next)));
    return next;
  }

  /// When [part] was fitted (null clears it), and for tyres the odometer
  /// then. Only moves forward when [onlyIfNewer], so logging an old "Tyres"
  /// expense doesn't wind back a later fitting.
  Future<bool> recordFitting(
    int vehicleId,
    WearPart part,
    DateTime? fitted, {
    int? km,
    bool onlyIfNewer = false,
  }) async {
    final v = _ref.read(garageProvider).vehicle(vehicleId);
    if (v == null) return false;
    final current = fittedDate(v, part);
    if (onlyIfNewer &&
        current != null &&
        (fitted == null || !fitted.isAfter(current))) {
      return false;
    }
    await _ref.read(vehicleRepositoryProvider).save(switch (part) {
      WearPart.tyres => v.copyWith(
        tyresFitted: Value(fitted),
        tyresFittedKm: Value(fitted == null ? null : km),
      ),
      WearPart.battery => v.copyWith(batteryFitted: Value(fitted)),
    });
    return true;
  }
}
