import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/expenses/domain/expense_category.dart';
import '../features/expenses/presentation/expense_form_screen.dart';
import '../features/expenses/presentation/expenses_screen.dart';
import '../features/expenses/presentation/recurring_form_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/service/presentation/schedules_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/vehicles/presentation/vehicle_detail_screen.dart';
import '../features/vehicles/presentation/vehicle_form_screen.dart';
import '../features/vehicles/presentation/vehicles_screen.dart';
import 'nav_shell.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => NavShell(shell: shell),
        branches: [
          _tab(AppRoutes.home, const HomeScreen()),
          _tab(AppRoutes.vehicles, const VehiclesScreen()),
          _tab(AppRoutes.expenses, const ExpensesScreen()),
          _tab(AppRoutes.settings, const SettingsScreen()),
        ],
      ),
      // Everything below opens full-screen over the tabs (no bottom bar).
      GoRoute(
        path: AppRoutes.newVehicle,
        builder: (_, _) => const VehicleFormScreen(),
      ),
      GoRoute(
        path: '/vehicle/:id',
        builder: (_, s) => VehicleDetailScreen(vehicleId: _id(s)),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, s) => VehicleFormScreen(vehicleId: _id(s)),
          ),
          GoRoute(
            path: 'schedules',
            builder: (_, s) => SchedulesScreen(vehicleId: _id(s)),
          ),
        ],
      ),
      GoRoute(
        path: '/expense/new',
        builder: (_, s) {
          final q = s.uri.queryParameters;
          return ExpenseFormScreen(
            initialVehicleId: int.tryParse(q['vehicle'] ?? ''),
            initialCategory: ExpenseCategory.values
                .where((c) => c.name == q['category'])
                .firstOrNull,
            initialScheduleId: int.tryParse(q['schedule'] ?? ''),
            recurringId: int.tryParse(q['recurring'] ?? ''),
            recurringDue: DateTime.tryParse(q['due'] ?? ''),
          );
        },
      ),
      // The list of recurring costs lives in the Expenses tab.
      GoRoute(
        path: AppRoutes.newRecurring,
        builder: (_, _) => const RecurringFormScreen(),
      ),
      GoRoute(
        path: '/recurring/:id',
        builder: (_, s) => RecurringFormScreen(recurringId: _id(s)),
      ),
      GoRoute(
        path: '/expense/:id',
        builder: (_, s) => ExpenseFormScreen(expenseId: _id(s)),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

StatefulShellBranch _tab(String path, Widget screen) => StatefulShellBranch(
  routes: [
    GoRoute(
      path: path,
      pageBuilder: (_, s) => NoTransitionPage(key: s.pageKey, child: screen),
    ),
  ],
);

int _id(GoRouterState s) => int.parse(s.pathParameters['id']!);
