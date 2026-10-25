import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

class RecurringRepository {
  RecurringRepository(this._db);

  final AppDatabase _db;

  Future<int> add(RecurringExpensesCompanion r) =>
      _db.into(_db.recurringExpenses).insert(r);

  Future<void> save(RecurringExpense r) =>
      _db.update(_db.recurringExpenses).replace(r);

  Future<void> delete(int id) =>
      (_db.delete(_db.recurringExpenses)..where((r) => r.id.equals(id))).go();

  /// Moves past the next due date (logged or skipped).
  Future<void> markHandled(int id) => _db.customUpdate(
    'UPDATE recurring_expenses SET handled_count = handled_count + 1 '
    'WHERE id = ?',
    variables: [Variable.withInt(id)],
    updates: {_db.recurringExpenses},
  );
}
