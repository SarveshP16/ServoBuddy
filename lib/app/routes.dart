/// Every path in the app, in one place.
abstract final class AppRoutes {
  static const home = '/';
  static const vehicles = '/vehicles';
  static const expenses = '/expenses';
  static const settings = '/settings';

  static const newVehicle = '/vehicle/new';
  static String vehicle(int id) => '/vehicle/$id';
  static String editVehicle(int id) => '/vehicle/$id/edit';
  static String schedules(int id) => '/vehicle/$id/schedules';

  /// Log expense, optionally preset. `category=service&schedule=3` is how
  /// "Add service record" and "Mark done" open the same form.
  /// `recurring=2&due=2026-10-01` logs that recurring cost's due payment.
  static String newExpense({
    int? vehicleId,
    String? category,
    int? scheduleId,
    int? recurringId,
    DateTime? due,
  }) {
    final query = {
      'vehicle': ?vehicleId?.toString(),
      'category': ?category,
      'schedule': ?scheduleId?.toString(),
      'recurring': ?recurringId?.toString(),
      'due': ?due?.toIso8601String().substring(0, 10),
    };
    return Uri(
      path: '/expense/new',
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }

  static String expense(int id) => '/expense/$id';

  static const newRecurring = '/recurring/new';
  static String editRecurring(int id) => '/recurring/$id';
}
