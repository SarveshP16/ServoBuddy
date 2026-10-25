import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers.dart';
import '../data/recurring_repository.dart';
import '../domain/expense_category.dart';
import '../domain/recurrence.dart';

/// What the recurring-cost form collects.
class RecurringDraft {
  const RecurringDraft({
    required this.vehicleId,
    required this.category,
    required this.amountCents,
    required this.title,
    required this.frequency,
    required this.nextDue,
  });

  final int vehicleId;
  final ExpenseCategory category;
  final int amountCents;
  final String? title;
  final RecurFrequency frequency;

  /// The next date it's due.
  final DateTime nextDue;
}

final recurringActionsProvider = Provider<RecurringActions>(
  RecurringActions.new,
);

class RecurringActions {
  RecurringActions(this._ref);

  final Ref _ref;

  RecurringRepository get _repo => _ref.read(recurringRepositoryProvider);

  /// Logs [r]'s due payment on [due] as-is and moves on to the next date.
  Future<void> logDue(RecurringExpense r, DateTime due) =>
      _ref.read(databaseProvider).transaction(() async {
        await _ref
            .read(expenseRepositoryProvider)
            .add(
              ExpensesCompanion.insert(
                vehicleId: r.vehicleId,
                category: r.category,
                amountCents: r.amountCents,
                date: due,
                title: Value(r.title),
              ),
            );
        await _repo.markHandled(r.id);
      });

  /// Passes over the due payment without logging it.
  Future<void> skip(RecurringExpense r) => _repo.markHandled(r.id);

  /// After a payment was logged through the full expense form instead.
  Future<void> markLogged(int id) => _repo.markHandled(id);

  Future<int> create(RecurringDraft d, {bool firstAlreadyLogged = false}) =>
      _repo.add(
        RecurringExpensesCompanion.insert(
          vehicleId: d.vehicleId,
          category: d.category,
          amountCents: d.amountCents,
          title: Value(d.title),
          frequency: d.frequency,
          startDate: d.nextDue,
          // When created from an expense just logged, that expense *is* the
          // first payment.
          handledCount: Value(firstAlreadyLogged ? 1 : 0),
        ),
      );

  /// Changing the schedule restarts the count from the new next-due date;
  /// changing only the amount or label keeps it.
  Future<void> update(RecurringExpense r, RecurringDraft d) {
    final next = occurrence(r.startDate, r.frequency, r.handledCount);
    final rescheduled = d.frequency != r.frequency || d.nextDue != next;
    return _repo.save(
      r.copyWith(
        vehicleId: d.vehicleId,
        category: d.category,
        amountCents: d.amountCents,
        title: Value(d.title),
        frequency: d.frequency,
        startDate: rescheduled ? d.nextDue : r.startDate,
        handledCount: rescheduled ? 0 : r.handledCount,
      ),
    );
  }

  Future<void> setPaused(RecurringExpense r, bool paused) =>
      _repo.save(r.copyWith(paused: paused));

  Future<void> delete(int id) => _repo.delete(id);
}
