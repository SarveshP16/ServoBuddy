import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/expenses/data/expense_repository.dart';
import '../features/expenses/data/recurring_repository.dart';
import '../features/garage/data/garage_repository.dart';
import '../features/service/data/schedule_repository.dart';
import '../features/settings/data/settings_repository.dart';
import '../features/vehicles/data/vehicle_repository.dart';
import 'database/app_database.dart';
import 'files/image_store.dart';
import 'notifications/notification_service.dart';

/// Overridden in `main()` once preferences have loaded, so settings can be
/// read synchronously everywhere.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

/// Overridden in `main()` (on-device file) and tests (in memory).
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

/// "Now", swappable so tests can pin the date.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final imageStoreProvider = Provider<ImageStore>((ref) => ImageStore());

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

final packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

final garageRepositoryProvider = Provider<GarageRepository>(
  (ref) =>
      GarageRepository(ref.watch(databaseProvider), ref.watch(clockProvider)),
);

final vehicleRepositoryProvider = Provider<VehicleRepository>(
  (ref) => VehicleRepository(ref.watch(databaseProvider)),
);

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ExpenseRepository(ref.watch(databaseProvider)),
);

final recurringRepositoryProvider = Provider<RecurringRepository>(
  (ref) => RecurringRepository(ref.watch(databaseProvider)),
);

final scheduleRepositoryProvider = Provider<ScheduleRepository>(
  (ref) => ScheduleRepository(ref.watch(databaseProvider)),
);
