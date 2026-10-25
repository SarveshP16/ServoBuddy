import '../../../core/database/app_database.dart';
import '../../../core/utils/calendar.dart';
import '../../expenses/domain/expense_category.dart';
import '../../expenses/domain/fuel_economy.dart';
import '../../expenses/domain/recurrence.dart';
import '../../service/domain/service_due.dart';
import '../../vehicles/domain/odometer.dart';
import '../../vehicles/domain/vehicle_alert.dart';
import '../../vehicles/domain/vehicle_status.dart';

/// Everything the app knows, loaded in one go, with the derived figures
/// (odometer, pace, service dues, alerts) worked out on demand.
///
/// A personal garage is a handful of cars and a few hundred expenses, so
/// recomputing from whole tables on every change is cheap, and it keeps all
/// the maths in plain, testable Dart rather than SQL.
class Garage {
  Garage({
    required List<Vehicle> vehicles,
    required this.readings,
    required this.schedules,
    required List<Expense> expenses,
    this.recurring = const [],
    required DateTime today,
  }) : today = dateOnly(today),
       allVehicles = [...vehicles]..sort(_primaryFirst),
       expenses = [...expenses]..sort(_newestFirst);

  static final empty = Garage(
    vehicles: const [],
    readings: const [],
    schedules: const [],
    expenses: const [],
    today: DateTime(2000),
  );

  final DateTime today;

  /// Every car ever added, including sold and deleted-with-history ones.
  /// Only for looking up names; lists and reminders use [vehicles].
  final List<Vehicle> allVehicles;

  /// Cars in use: primary first, then in the order they were added.
  late final List<Vehicle> vehicles = [
    for (final v in allVehicles)
      if (v.status == VehicleStatus.active) v,
  ];

  /// Sold / not in use, most recently retired first.
  late final List<Vehicle> retiredVehicles =
      [
        for (final v in allVehicles)
          if (v.status == VehicleStatus.retired) v,
      ]..sort(
        (a, b) =>
            (b.soldDate ?? b.createdAt).compareTo(a.soldDate ?? a.createdAt),
      );

  /// Newest first.
  final List<Expense> expenses;
  final List<OdometerReading> readings;

  /// Repeating costs, in the order they were added.
  final List<RecurringExpense> recurring;
  final List<ServiceSchedule> schedules;

  bool get isEmpty => vehicles.isEmpty;

  Vehicle? get primary => vehicles.isEmpty ? null : vehicles.first;

  /// Any car by id, whatever its status (for labelling its expenses).
  Vehicle? vehicle(int id) {
    for (final v in allVehicles) {
      if (v.id == id) return v;
    }
    return null;
  }

  /// True only for a car in use — the test for anything that reminds, picks
  /// or defaults.
  bool isActive(int id) => vehicle(id)?.status == VehicleStatus.active;

  /// Everything ever spent on a car.
  int lifetimeSpend(int vehicleId) =>
      expensesFor(vehicleId).fold(0, (sum, e) => sum + e.amountCents);

  List<Expense> expensesFor(int vehicleId) =>
      _expensesByVehicle[vehicleId] ?? const [];

  /// Service records, newest first.
  List<Expense> serviceHistoryFor(int vehicleId) =>
      expensesFor(vehicleId)
          .where((e) => e.category == ExpenseCategory.service)
          .toList();

  List<ServiceSchedule> schedulesFor(int vehicleId) =>
      schedules.where((s) => s.vehicleId == vehicleId).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  ServiceSchedule? schedule(int id) {
    for (final s in schedules) {
      if (s.id == id) return s;
    }
    return null;
  }

  Expense? expense(int id) {
    for (final e in expenses) {
      if (e.id == id) return e;
    }
    return null;
  }

  List<OdometerSample> odometerSamplesFor(int vehicleId) => [
    for (final r in readings)
      if (r.vehicleId == vehicleId) OdometerSample(r.date, r.km),
    for (final e in expensesFor(vehicleId))
      if (e.odometerKm != null) OdometerSample(e.date, e.odometerKm!),
  ];

  int? odometerOf(int vehicleId) => _odometer
      .putIfAbsent(
        vehicleId,
        () => (currentOdometer(odometerSamplesFor(vehicleId)),),
      )
      .$1;

  double? kmPerDayOf(int vehicleId) => _pace
      .putIfAbsent(
        vehicleId,
        () => (kmPerDay(odometerSamplesFor(vehicleId), today),),
      )
      .$1;

  /// Every schedule's due point, most urgent first.
  List<ServiceDue> duesFor(int vehicleId) => _dues.putIfAbsent(vehicleId, () {
    final records = serviceHistoryFor(vehicleId);
    return [
      for (final s in schedulesFor(vehicleId))
        computeServiceDue(
          schedule: s,
          records: records,
          currentKm: odometerOf(vehicleId),
          kmPerDay: kmPerDayOf(vehicleId),
          today: today,
        ),
    ]..sort(compareUrgency);
  });

  ServiceDue? nextDueFor(int vehicleId) {
    final dues = duesFor(vehicleId);
    return dues.isEmpty || dues.first.status == DueStatus.unknown
        ? null
        : dues.first;
  }

  /// The most urgent service across the whole garage (the Home stat tile).
  ({Vehicle vehicle, ServiceDue due})? get mostUrgentDue {
    ({Vehicle vehicle, ServiceDue due})? best;
    for (final v in vehicles) {
      final due = nextDueFor(v.id);
      if (due == null) continue;
      if (best == null || compareUrgency(due, best.due) < 0) {
        best = (vehicle: v, due: due);
      }
    }
    return best;
  }

  RecurringExpense? recurringById(int id) {
    for (final r in recurring) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Recurring costs with a due date that has arrived and hasn't been logged
  /// or skipped, oldest due first, with how many are waiting for each.
  List<({RecurringExpense item, DateTime due, int waiting})>
  get pendingRecurring => [
    for (final r in recurring)
      // A sold car's recurring costs go quiet until it's back in use.
      if (!r.paused && isActive(r.vehicleId))
        if (pendingOccurrences(
              start: r.startDate,
              frequency: r.frequency,
              handled: r.handledCount,
              today: today,
            )
            case final dues when dues.isNotEmpty)
          (item: r, due: dues.first, waiting: dues.length),
  ]..sort((a, b) => a.due.compareTo(b.due));

  VehicleAlert? alertOf(Vehicle v) => alertFor(v, duesFor(v.id), today);

  FuelStats fuelStatsFor(int vehicleId) => fuelStats(expensesFor(vehicleId));

  late final Map<int, List<Expense>> _expensesByVehicle = () {
    final map = <int, List<Expense>>{};
    for (final e in expenses) {
      (map[e.vehicleId] ??= []).add(e);
    }
    return map;
  }();

  final _odometer = <int, (int?,)>{};
  final _pace = <int, (double?,)>{};
  final _dues = <int, List<ServiceDue>>{};

  static int _primaryFirst(Vehicle a, Vehicle b) {
    if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
    return a.createdAt.compareTo(b.createdAt);
  }

  static int _newestFirst(Expense a, Expense b) {
    final byDate = b.date.compareTo(a.date);
    return byDate != 0 ? byDate : b.id.compareTo(a.id);
  }
}
