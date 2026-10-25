import 'package:intl/intl.dart';

import '../utils/calendar.dart';

final _day = DateFormat('d MMM yyyy');
final _dayPadded = DateFormat('dd MMM yyyy');
final _month = DateFormat('MMMM yyyy');

/// "22 Sep 2026".
String formatDate(DateTime d) => _day.format(d);

/// "02 Mar 2026" — the service-history rows pad the day, as mocked.
String formatDatePadded(DateTime d) => _dayPadded.format(d);

/// "September 2026".
String formatMonth(DateTime d) => _month.format(d);

/// "Today", "Yesterday", else "22 Sep 2026".
String formatRelativeDay(DateTime d, DateTime now) {
  switch (daysBetween(d, now)) {
    case 0:
      return 'Today';
    case 1:
      return 'Yesterday';
    default:
      return formatDate(d);
  }
}

/// A rough span in words for "~3 weeks": days, then weeks, then months.
String formatApproxSpan(int days) {
  if (days <= 1) return days <= 0 ? 'today' : '1 day';
  if (days < 14) return '$days days';
  if (days < 63) return '${(days / 7).round()} weeks';
  final months = (days / 30.4).round();
  return months == 1 ? '1 month' : '$months months';
}

/// "Good morning" / "Good afternoon" / "Good evening".
String greetingFor(DateTime now) {
  if (now.hour < 12) return 'Good morning';
  if (now.hour < 17) return 'Good afternoon';
  return 'Good evening';
}
