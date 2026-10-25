import '../../../core/database/app_database.dart';
import '../../../core/format/dates.dart';
import '../domain/recurrence.dart';

extension RecurringLabels on RecurringExpense {
  /// "Linkt top-up", else the category name.
  String get label => title ?? category.label;

  DateTime get nextDue => occurrence(startDate, frequency, handledCount);

  /// "Monthly · next 1 Oct 2026", or "Monthly · paused".
  String get scheduleLine =>
      '${frequency.label} · ${paused ? 'paused' : 'next ${formatDate(nextDue)}'}';
}
