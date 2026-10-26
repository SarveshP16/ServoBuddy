import '../../../core/format/money.dart';
import '../../expenses/domain/spend_summary.dart';
import '../../garage/domain/garage.dart';
import '../../reminders/presentation/upcoming_items.dart';
import '../../vehicles/domain/vehicle_labels.dart';

/// What the home screen widget shows: the next thing due, and this month's
/// spend across all cars.
typedef WidgetSnapshot = ({
  String dueTitle,
  String dueDetail,

  /// The car the due item belongs to; tapping the widget opens it.
  int? vehicleId,
  String monthSpend,
  String monthLabel,
});

WidgetSnapshot widgetSnapshot(Garage garage) {
  final next = upcomingItems(garage).firstOrNull;
  final today = garage.today;
  final monthCents = sumCents(
    garage.expenses.where(
      (e) => e.date.year == today.year && e.date.month == today.month,
    ),
  );
  return (
    dueTitle: next == null
        ? (garage.isEmpty ? 'Add your car' : 'Nothing due')
        : '${next.title} — ${next.vehicle.shortName}',
    dueDetail: next == null
        ? (garage.isEmpty
              ? 'Open ServoBuddy to get started'
              : 'Set reminders to see what’s next')
        : next.detail,
    vehicleId: next?.vehicle.id,
    monthSpend: formatMoney(monthCents),
    monthLabel: 'This month',
  );
}
