import '../../../core/format/dates.dart';
import '../../../core/format/numbers.dart';
import '../domain/service_due.dart';

/// "Oil change due" / "Oil change overdue".
String dueHeadline(ServiceDue d) => d.status == DueStatus.overdue
    ? '${d.schedule.name} overdue'
    : '${d.schedule.name} due';

/// "in 850 km · ~3 weeks", "in 3 weeks", "by 120 km · since 12 Sep 2026".
String dueDetail(ServiceDue d) {
  if (d.status == DueStatus.overdue) {
    return [
      if (d.kmLeft != null && d.kmLeft! <= 0) 'by ${formatKm(-d.kmLeft!)}',
      if (d.daysLeftByDate != null && d.daysLeftByDate! < 0)
        'since ${formatDate(d.dueDate!)}',
    ].join(' · ');
  }
  final days = d.estimatedDaysLeft;
  final span = days == null ? null : formatApproxSpan(days);
  if (d.kmLeft == null) {
    return span == null ? '' : (days! <= 0 ? span : 'in $span');
  }
  return [
    'in ${formatKm(d.kmLeft!)}',
    if (span != null) d.dateBound ? span : '~$span',
  ].join(' · ');
}

/// Compact form for the Home stat tile: the big number and a unit line.
/// "850 km" if a km limit applies, else "3 weeks"; "Overdue" when overdue.
String dueStatValue(ServiceDue d) {
  if (d.status == DueStatus.overdue) return 'Overdue';
  if (d.kmLeft != null) return formatKm(d.kmLeft!);
  final days = d.estimatedDaysLeft;
  return days == null ? '—' : formatApproxSpan(days);
}
