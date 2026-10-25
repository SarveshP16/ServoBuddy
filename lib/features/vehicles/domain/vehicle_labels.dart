import '../../../core/database/app_database.dart';

extension VehicleLabels on Vehicle {
  /// "Toyota Corolla".
  String get displayName => '$make $model';

  /// "Corolla" — the short name used in "Fuel — Corolla".
  String get shortName => model;
}
