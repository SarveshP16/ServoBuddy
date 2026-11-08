import 'package:servobuddy/core/database/app_database.dart';
import 'package:servobuddy/features/expenses/domain/expense_category.dart';
import 'package:servobuddy/features/vehicles/domain/body_type.dart';
import 'package:servobuddy/features/vehicles/domain/fuel_type.dart';
import 'package:servobuddy/features/vehicles/domain/vehicle_status.dart';
import 'package:servobuddy/features/wash/domain/wash_type.dart';

/// Plain data-class builders for pure-logic tests (no database).
Vehicle vehicle({
  int id = 1,
  String make = 'Toyota',
  String model = 'Corolla',
  bool isPrimary = true,
  int year = 2019,
  DateTime? regoExpiry,
  DateTime? insuranceExpiry,
  FuelType fuelType = FuelType.e10,
  VehicleStatus status = VehicleStatus.active,
  DateTime? tyresFitted,
  int? tyresFittedKm,
  DateTime? batteryFitted,
  int? washEveryDays,
}) => Vehicle(
  id: id,
  make: make,
  model: model,
  year: year,
  bodyType: BodyType.sedan,
  fuelType: fuelType,
  rego: '7XY-2KL',
  photoPath: null,
  regoExpiry: regoExpiry,
  insuranceExpiry: insuranceExpiry,
  isPrimary: isPrimary,
  createdAt: DateTime(2026, 1, 1),
  status: status,
  soldDate: null,
  salePriceCents: null,
  tyresFitted: tyresFitted,
  tyresFittedKm: tyresFittedKm,
  batteryFitted: batteryFitted,
  washEveryDays: washEveryDays,
);

Expense expense({
  int id = 1,
  int vehicleId = 1,
  ExpenseCategory category = ExpenseCategory.fuel,
  int amountCents = 6840,
  required DateTime date,
  String? title,
  double? litres,
  bool fullTank = true,
  int? odometerKm,
  int? scheduleId,
}) => Expense(
  id: id,
  vehicleId: vehicleId,
  category: category,
  amountCents: amountCents,
  date: date,
  title: title,
  notes: null,
  receiptPath: null,
  litres: litres,
  fullTank: fullTank,
  odometerKm: odometerKm,
  scheduleId: scheduleId,
);

ServiceSchedule schedule({
  int id = 1,
  int vehicleId = 1,
  String name = 'Oil change',
  int? intervalKm = 10000,
  int? intervalMonths = 12,
  int? baselineKm,
  DateTime? baselineDate,
}) => ServiceSchedule(
  id: id,
  vehicleId: vehicleId,
  name: name,
  intervalKm: intervalKm,
  intervalMonths: intervalMonths,
  baselineKm: baselineKm,
  baselineDate: baselineDate,
);

OdometerReading reading(
  int km,
  DateTime date, {
  int id = 1,
  int vehicleId = 1,
}) => OdometerReading(id: id, vehicleId: vehicleId, date: date, km: km);

Wash wash({
  int id = 1,
  int vehicleId = 1,
  required DateTime date,
  WashType type = WashType.automatic,
  String? place,
  int amountCents = 0,
  int? expenseId,
}) => Wash(
  id: id,
  vehicleId: vehicleId,
  date: date,
  type: type,
  place: place,
  amountCents: amountCents,
  usedPass: false,
  expenseId: expenseId,
  checklist: null,
  itemsDone: null,
  itemsTotal: null,
  minutes: null,
  notes: null,
);
