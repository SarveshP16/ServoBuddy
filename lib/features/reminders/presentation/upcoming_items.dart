import '../../../core/database/app_database.dart';
import '../../../core/format/dates.dart';
import '../../../core/utils/calendar.dart';
import '../../garage/domain/garage.dart';
import '../../service/domain/service_due.dart';
import '../../service/presentation/due_text.dart';
import '../../vehicles/domain/vehicle_alert.dart';
import '../domain/nsw_slips.dart';

/// Green and pink slips are listed once rego is this close.
const slipHorizonDays = 60;

enum UpcomingKind { service, rego, insurance, greenSlip, pinkSlip }

/// One thing coming up for one car, for the list behind Home's bell.
class UpcomingItem {
  const UpcomingItem({
    required this.vehicle,
    required this.kind,
    required this.title,
    required this.detail,
    required this.urgent,
    required this.daysLeft,
  });

  final Vehicle vehicle;
  final UpcomingKind kind;
  final String title;
  final String detail;

  /// Due soon or overdue.
  final bool urgent;

  /// For ordering; null sorts last.
  final int? daysLeft;
}

/// Everything with a known due point, most pressing first.
List<UpcomingItem> upcomingItems(Garage garage) {
  final items = <UpcomingItem>[];
  for (final v in garage.vehicles) {
    for (final d in garage.duesFor(v.id)) {
      if (d.status == DueStatus.unknown) continue;
      items.add(
        UpcomingItem(
          vehicle: v,
          kind: UpcomingKind.service,
          title: dueHeadline(d),
          detail: dueDetail(d),
          urgent: d.status == DueStatus.soon || d.status == DueStatus.overdue,
          daysLeft: d.status == DueStatus.overdue ? -1 : d.estimatedDaysLeft,
        ),
      );
    }

    void renewal(DateTime? expiry, UpcomingKind kind, String what) {
      if (expiry == null) return;
      final days = daysBetween(garage.today, expiry);
      items.add(
        UpcomingItem(
          vehicle: v,
          kind: kind,
          title: days < 0 ? '$what expired' : '$what renewal',
          detail: days < 0
              ? 'since ${formatDate(expiry)}'
              : '${formatDate(expiry)} · ${days == 0 ? 'today' : 'in ${formatApproxSpan(days)}'}',
          urgent: days <= VehicleAlert.renewalWindowDays,
          daysLeft: days,
        ),
      );
    }

    renewal(v.regoExpiry, UpcomingKind.rego, 'Rego');
    renewal(v.insuranceExpiry, UpcomingKind.insurance, 'Insurance');

    // The slips only matter as renewal approaches; listing them months out
    // would just be noise.
    final slips = nswSlipsFor(v, garage.today);
    final regoDays = slips == null
        ? null
        : daysBetween(garage.today, slips.greenSlipBy);
    if (slips != null && regoDays! >= 0 && regoDays <= slipHorizonDays) {
      items.add(
        UpcomingItem(
          vehicle: v,
          kind: UpcomingKind.greenSlip,
          title: 'CTP green slip',
          detail: 'Buy before rego renews · ${formatDate(slips.greenSlipBy)}',
          urgent: regoDays <= VehicleAlert.renewalWindowDays,
          daysLeft: regoDays,
        ),
      );
      final pinkFrom = slips.pinkSlipFrom;
      if (pinkFrom != null) {
        final open = !garage.today.isBefore(pinkFrom);
        items.add(
          UpcomingItem(
            vehicle: v,
            kind: UpcomingKind.pinkSlip,
            title: 'Pink slip',
            detail: open
                ? 'Safety check window open · rego ${formatDate(slips.greenSlipBy)}'
                : 'Safety check window opens ${formatDate(pinkFrom)}',
            urgent: open,
            daysLeft: regoDays,
          ),
        );
      }
    }
  }

  items.sort((a, b) {
    if (a.urgent != b.urgent) return a.urgent ? -1 : 1;
    if (a.daysLeft == null && b.daysLeft == null) return 0;
    if (a.daysLeft == null) return 1;
    if (b.daysLeft == null) return -1;
    return a.daysLeft!.compareTo(b.daysLeft!);
  });
  return items;
}
