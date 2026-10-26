import 'package:drift/drift.dart';

import '../../features/expenses/domain/expense_category.dart';
import '../../features/expenses/domain/recurrence.dart';
import '../../features/vehicles/domain/body_type.dart';
import '../../features/vehicles/domain/fuel_type.dart';
import '../../features/vehicles/domain/vehicle_status.dart';

/// All dates are stored as local calendar dates at midnight (the app never cares
/// about time of day), except [Vehicles.createdAt].
class Vehicles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get make => text()();
  TextColumn get model => text()();
  IntColumn get year => integer()();
  TextColumn get bodyType => textEnum<BodyType>()();
  TextColumn get fuelType => textEnum<FuelType>()();

  /// Number plate. Optional: a car can be added before it's registered.
  TextColumn get rego => text().nullable()();

  /// A copy of the picked photo inside app storage, so it survives the
  /// gallery original being deleted.
  TextColumn get photoPath => text().nullable()();
  DateTimeColumn get regoExpiry => dateTime().nullable()();
  DateTimeColumn get insuranceExpiry => dateTime().nullable()();

  /// The main car: listed first, and the default for new expenses.
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  /// v3: sold / not in use, or deleted with its history kept.
  TextColumn get status =>
      textEnum<VehicleStatus>().withDefault(const Constant('active'))();

  /// v3: set when marked sold (both optional).
  DateTimeColumn get soldDate => dateTime().nullable()();
  IntColumn get salePriceCents => integer().nullable()();

  /// v4: when the current tyres and battery went on, for replacement
  /// estimates. Often paid as part of a service, so set by hand as well as
  /// from a "Tyres" or "Battery" expense.
  DateTimeColumn get tyresFitted => dateTime().nullable()();
  IntColumn get tyresFittedKm => integer().nullable()();
  DateTimeColumn get batteryFitted => dateTime().nullable()();
}

/// Odometer readings typed in directly (when adding or editing a car). Fuel
/// and service expenses carry their own readings; together they give the
/// current odometer and how fast it's rising.
class OdometerReadings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get vehicleId =>
      integer().references(Vehicles, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
  IntColumn get km => integer()();
}

/// A recurring service: "every [intervalKm] km or [intervalMonths] months,
/// whichever comes first". At least one interval is always set.
class ServiceSchedules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get vehicleId =>
      integer().references(Vehicles, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get intervalKm => integer().nullable()();
  IntColumn get intervalMonths => integer().nullable()();

  /// When it was last done *before* the app knew about the car. Service
  /// records logged in the app take over once they're more recent.
  IntColumn get baselineKm => integer().nullable()();
  DateTimeColumn get baselineDate => dateTime().nullable()();
}

/// Every cost. A service record is simply an expense in the Service category,
/// optionally tied to the [scheduleId] it satisfies.
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get vehicleId =>
      integer().references(Vehicles, #id, onDelete: KeyAction.cascade)();
  TextColumn get category => textEnum<ExpenseCategory>()();

  /// Stored in cents so totals never pick up floating-point drift.
  IntColumn get amountCents => integer()();
  DateTimeColumn get date => dateTime()();

  /// Service records only: "Logbook service", "Tyre rotation".
  TextColumn get title => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get receiptPath => text().nullable()();

  /// Fuel only.
  RealColumn get litres => real().nullable()();

  /// Filled to full? Economy is only measurable between two full fills.
  BoolColumn get fullTank => boolean().withDefault(const Constant(true))();

  /// Fuel and service: the odometer at the time.
  IntColumn get odometerKm => integer().nullable()();
  IntColumn get scheduleId => integer().nullable().references(
    ServiceSchedules,
    #id,
    onDelete: KeyAction.setNull,
  )();
}

/// A cost that repeats (monthly insurance, a toll-pass top-up). Nothing is
/// logged automatically: on each due date you're reminded, and the expense is
/// only created when you confirm it.
///
/// Due dates are counted from [startDate] (see `occurrence`), and
/// [handledCount] is how many of them have been logged or skipped, so the
/// next one is always `occurrence(startDate, frequency, handledCount)`.
class RecurringExpenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get vehicleId =>
      integer().references(Vehicles, #id, onDelete: KeyAction.cascade)();
  TextColumn get category => textEnum<ExpenseCategory>()();
  IntColumn get amountCents => integer()();

  /// "Linkt top-up". Falls back to the category name.
  TextColumn get title => text().nullable()();
  TextColumn get frequency => textEnum<RecurFrequency>()();

  /// The first due date.
  DateTimeColumn get startDate => dateTime()();
  IntColumn get handledCount => integer().withDefault(const Constant(0))();
  BoolColumn get paused => boolean().withDefault(const Constant(false))();
}
