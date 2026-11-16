import '../../../core/format/numbers.dart';
import '../domain/service_due.dart';

/// "Oil change due" / "Oil change overdue".
String dueHeadline(ServiceDue d) => d.status == DueStatus.overdue
    ? '${d.schedule.name} overdue'
    : '${d.schedule.name} due';

/// "in 850 km · at 43,030 km", or "by 120 km" once overdue. Km only: when a
/// service falls due depends on the odometer, not the calendar.
String dueDetail(ServiceDue d) {
  final left = d.kmLeft;
  if (left == null) return '';
  if (left <= 0) return 'by ${formatKm(-left)}';
  return [
    'in ${formatKm(left)}',
    if (d.dueKm != null) 'at ${formatKm(d.dueKm!)}',
  ].join(' · ');
}

/// Compact form for the Home stat tile: "850 km", or "Overdue".
String dueStatValue(ServiceDue d) {
  if (d.status == DueStatus.overdue) return 'Overdue';
  return d.kmLeft == null ? '—' : formatKm(d.kmLeft!);
}
