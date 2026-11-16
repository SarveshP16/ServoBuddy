import '../../../core/database/app_database.dart';
import '../../../core/utils/calendar.dart';

enum DueStatus { ok, soon, overdue, unknown }

/// How close a service is, by the odometer.
///
/// Services fall due by km only: last service km plus the interval. A
/// schedule's months (from before 1.6.1) are ignored.
class ServiceDue {
  const ServiceDue({
    required this.schedule,
    required this.lastKm,
    required this.lastDate,
    required this.dueKm,
    required this.kmLeft,
    required this.estimatedDaysLeft,
    required this.status,
  });

  /// Within this many km counts as "due soon".
  static const soonKm = 1000;

  final ServiceSchedule schedule;
  final int? lastKm;
  final DateTime? lastDate;
  final int? dueKm;

  /// Negative once overdue.
  final int? kmLeft;

  /// How long [kmLeft] should take at the car's usual pace. Only for timing
  /// reminders and ordering; never shown, since the due point is the km.
  final int? estimatedDaysLeft;
  final DueStatus status;

  /// The day the car should reach [dueKm] (for reminders).
  DateTime? estimatedDueDate(DateTime today) =>
      estimatedDaysLeft == null ? null : addDays(today, estimatedDaysLeft!);
}

/// Works out [schedule]'s next due point.
///
/// "Last done" is the most recent of the schedule's baseline and any service
/// record logged against it.
ServiceDue computeServiceDue({
  required ServiceSchedule schedule,
  required Iterable<Expense> records,
  required int? currentKm,
  required double? kmPerDay,
  required DateTime today,
}) {
  var lastDate = schedule.baselineDate;
  var lastKm = schedule.baselineKm;
  for (final r in records) {
    if (r.scheduleId != schedule.id) continue;
    if (lastDate == null || !r.date.isBefore(lastDate)) {
      lastDate = r.date;
      // A record without a reading still counts as the latest; the km falls
      // back to the best we already knew.
      lastKm = r.odometerKm ?? lastKm;
    }
  }

  final dueKm = (lastKm != null && schedule.intervalKm != null)
      ? lastKm + schedule.intervalKm!
      : null;
  final kmLeft = (dueKm != null && currentKm != null)
      ? dueKm - currentKm
      : null;

  int? estimatedDaysLeft;
  if (kmLeft != null && kmPerDay != null && kmPerDay > 0) {
    estimatedDaysLeft = kmLeft <= 0 ? 0 : (kmLeft / kmPerDay).ceil();
  }

  final status = kmLeft == null
      ? DueStatus.unknown
      : kmLeft <= 0
      ? DueStatus.overdue
      : kmLeft <= ServiceDue.soonKm
      ? DueStatus.soon
      : DueStatus.ok;

  return ServiceDue(
    schedule: schedule,
    lastKm: lastKm,
    lastDate: lastDate,
    dueKm: dueKm,
    kmLeft: kmLeft,
    estimatedDaysLeft: estimatedDaysLeft,
    status: status,
  );
}

/// Most urgent first: overdue, then soon, then fewest km left.
int compareUrgency(ServiceDue a, ServiceDue b) {
  int rank(DueStatus s) => switch (s) {
    DueStatus.overdue => 0,
    DueStatus.soon => 1,
    DueStatus.ok => 2,
    DueStatus.unknown => 3,
  };
  final byStatus = rank(a.status).compareTo(rank(b.status));
  if (byStatus != 0) return byStatus;
  return _nullsLast(a.kmLeft, b.kmLeft);
}

int _nullsLast(int? a, int? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}
