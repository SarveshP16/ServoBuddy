import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/format/numbers.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/utils/calendar.dart';
import '../../expenses/domain/recurrence.dart';
import '../../garage/domain/garage.dart';
import '../../vehicles/domain/vehicle_labels.dart';
import 'nsw_slips.dart';

/// Reminders go out at 9 am, this many days ahead and again on the day.
const reminderHour = 9;
const reminderLeadDays = 14;

/// Everything that should be scheduled right now, given the garage.
///
/// Rebuilt from scratch on every change: service estimates move as odometer
/// readings come in, so yesterday's plan is never reused.
List<PlannedNotification> planReminders(Garage garage, DateTime now) {
  final out = <({DateTime at, String title, String body})>[];

  void at(DateTime day, String title, String body) {
    final when = DateTime(day.year, day.month, day.day, reminderHour);
    if (when.isAfter(now)) out.add((at: when, title: title, body: body));
  }

  for (final v in garage.vehicles) {
    final name = v.displayName;

    void renewal(DateTime? expiry, String what) {
      if (expiry == null) return;
      at(
        addDays(expiry, -reminderLeadDays),
        '$what due in 2 weeks — $name',
        '$what expires on ${formatDate(expiry)}.',
      );
      at(expiry, '$what expires today — $name', 'Renew it to stay covered.');
    }

    renewal(v.regoExpiry, 'Rego');
    renewal(v.insuranceExpiry, 'Insurance');

    final slips = nswSlipsFor(v, garage.today);
    if (slips != null) {
      final regoDay = formatDate(slips.greenSlipBy);
      at(
        slips.greenSlipReminder,
        'Buy your CTP green slip — $name',
        'You need it before renewing rego on $regoDay.',
      );
      if (slips.pinkSlipFrom != null) {
        at(
          slips.pinkSlipFrom!,
          'Pink slip checks now open — $name',
          'Get the safety check done before rego renews on $regoDay.',
        );
      }
    }

    for (final due in garage.duesFor(v.id)) {
      final dueDay = due.estimatedDueDate(garage.today);
      if (dueDay == null) continue;
      final service = due.schedule.name;
      final kmNote = due.dueKm == null ? '' : ' (at ${formatKm(due.dueKm!)})';
      at(
        addDays(dueDay, -reminderLeadDays),
        '$service due soon — $name',
        due.dateBound
            ? '$service is due on ${formatDate(dueDay)}$kmNote.'
            : '$service is due in about 2 weeks$kmNote.',
      );
      at(dueDay, '$service due — $name', 'Time to book it in$kmNote.');
    }
  }

  // Recurring costs: one reminder for the next due date. Past-due ones
  // already show as "Log $X?" cards in the app, so they don't re-notify.
  for (final r in garage.recurring) {
    // Sold / not in use: no reminders until it's back in use.
    if (r.paused || !garage.isActive(r.vehicleId)) continue;
    final v = garage.vehicle(r.vehicleId)!;
    final label = r.title ?? r.category.label;
    at(
      occurrence(r.startDate, r.frequency, r.handledCount),
      '$label due — ${v.displayName}',
      'Open ServoBuddy to log the ${formatMoney(r.amountCents)} payment.',
    );
  }

  out.sort((a, b) => a.at.compareTo(b.at));
  return [
    for (final (i, r) in out.indexed)
      PlannedNotification(id: i + 1, title: r.title, body: r.body, at: r.at),
  ];
}
