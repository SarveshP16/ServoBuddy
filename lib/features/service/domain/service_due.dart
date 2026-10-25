import 'dart:math' as math;

import '../../../core/database/app_database.dart';
import '../../../core/utils/calendar.dart';

enum DueStatus { ok, soon, overdue, unknown }

/// How close a service is, and when it's likely to fall due.
class ServiceDue {
  const ServiceDue({
    required this.schedule,
    required this.lastKm,
    required this.lastDate,
    required this.dueKm,
    required this.dueDate,
    required this.kmLeft,
    required this.daysLeftByDate,
    required this.estimatedDaysLeft,
    required this.status,
  });

  /// Within this many km or days counts as "due soon".
  static const soonKm = 1000;
  static const soonDays = 30;

  final ServiceSchedule schedule;
  final int? lastKm;
  final DateTime? lastDate;
  final int? dueKm;
  final DateTime? dueDate;

  /// Negative once overdue.
  final int? kmLeft;
  final int? daysLeftByDate;

  /// The sooner of [daysLeftByDate] and how long [kmLeft] will take at the
  /// car's usual pace. Null if neither is known.
  final int? estimatedDaysLeft;
  final DueStatus status;

  /// True when the date limit, not the km estimate, is what comes first — the
  /// day count is then exact rather than approximate.
  bool get dateBound =>
      daysLeftByDate != null && daysLeftByDate == estimatedDaysLeft;

  /// The day it's expected to fall due (for reminders).
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
      // A record without a reading still resets the date; the km falls back
      // to the best we already knew.
      lastKm = r.odometerKm ?? lastKm;
    }
  }

  final dueKm = (lastKm != null && schedule.intervalKm != null)
      ? lastKm + schedule.intervalKm!
      : null;
  final dueDate = (lastDate != null && schedule.intervalMonths != null)
      ? addMonths(lastDate, schedule.intervalMonths!)
      : null;

  final kmLeft = (dueKm != null && currentKm != null)
      ? dueKm - currentKm
      : null;
  final daysLeftByDate = dueDate != null ? daysBetween(today, dueDate) : null;

  int? daysByKm;
  if (kmLeft != null && kmPerDay != null && kmPerDay > 0) {
    daysByKm = kmLeft <= 0 ? 0 : (kmLeft / kmPerDay).ceil();
  }
  final estimates = [?daysLeftByDate, ?daysByKm];
  final estimatedDaysLeft = estimates.isEmpty
      ? null
      : estimates.reduce(math.min);

  final DueStatus status;
  if ((kmLeft != null && kmLeft <= 0) ||
      (daysLeftByDate != null && daysLeftByDate < 0)) {
    status = DueStatus.overdue;
  } else if ((kmLeft != null && kmLeft <= ServiceDue.soonKm) ||
      (estimatedDaysLeft != null && estimatedDaysLeft <= ServiceDue.soonDays)) {
    status = DueStatus.soon;
  } else if (kmLeft == null && daysLeftByDate == null) {
    status = DueStatus.unknown;
  } else {
    status = DueStatus.ok;
  }

  return ServiceDue(
    schedule: schedule,
    lastKm: lastKm,
    lastDate: lastDate,
    dueKm: dueKm,
    dueDate: dueDate,
    kmLeft: kmLeft,
    daysLeftByDate: daysLeftByDate,
    estimatedDaysLeft: estimatedDaysLeft,
    status: status,
  );
}

/// Most urgent first: overdue, then soonest expected, then fewest km left.
int compareUrgency(ServiceDue a, ServiceDue b) {
  int rank(DueStatus s) => switch (s) {
    DueStatus.overdue => 0,
    DueStatus.soon => 1,
    DueStatus.ok => 2,
    DueStatus.unknown => 3,
  };
  final byStatus = rank(a.status).compareTo(rank(b.status));
  if (byStatus != 0) return byStatus;
  final byDays = _nullsLast(a.estimatedDaysLeft, b.estimatedDaysLeft);
  if (byDays != 0) return byDays;
  return _nullsLast(a.kmLeft, b.kmLeft);
}

int _nullsLast(int? a, int? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}
