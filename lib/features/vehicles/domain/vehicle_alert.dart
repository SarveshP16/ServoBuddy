import '../../../core/database/app_database.dart';
import '../../../core/utils/calendar.dart';
import '../../service/domain/service_due.dart';

/// The single most pressing thing about a car, for the badge on its list row.
/// Declared most severe first.
enum VehicleAlert {
  serviceOverdue('Service overdue'),
  regoExpired('Rego expired'),
  insuranceExpired('Insurance expired'),
  serviceDueSoon('Service due soon'),
  regoDueSoon('Rego due soon'),
  insuranceDueSoon('Insurance due soon');

  const VehicleAlert(this.label);

  final String label;

  /// Renewals show as "due soon" this many days out.
  static const renewalWindowDays = 30;
}

VehicleAlert? alertFor(Vehicle v, Iterable<ServiceDue> dues, DateTime today) {
  final found = <VehicleAlert>{};
  for (final d in dues) {
    if (d.status == DueStatus.overdue) found.add(VehicleAlert.serviceOverdue);
    if (d.status == DueStatus.soon) found.add(VehicleAlert.serviceDueSoon);
  }

  void renewal(DateTime? expiry, VehicleAlert expired, VehicleAlert soon) {
    if (expiry == null) return;
    final days = daysBetween(today, expiry);
    if (days < 0) {
      found.add(expired);
    } else if (days <= VehicleAlert.renewalWindowDays) {
      found.add(soon);
    }
  }

  renewal(v.regoExpiry, VehicleAlert.regoExpired, VehicleAlert.regoDueSoon);
  renewal(
    v.insuranceExpiry,
    VehicleAlert.insuranceExpired,
    VehicleAlert.insuranceDueSoon,
  );
  for (final a in VehicleAlert.values) {
    if (found.contains(a)) return a;
  }
  return null;
}
