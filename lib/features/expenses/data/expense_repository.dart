import '../../../core/database/app_database.dart';

class ExpenseRepository {
  ExpenseRepository(this._db);

  final AppDatabase _db;

  Future<int> add(ExpensesCompanion expense) =>
      _db.into(_db.expenses).insert(expense);

  Future<void> save(Expense expense) =>
      _db.update(_db.expenses).replace(expense);

  Future<void> delete(int id) =>
      (_db.delete(_db.expenses)..where((e) => e.id.equals(id))).go();

  /// Puts a deleted expense back exactly as it was (same id), for Undo.
  Future<void> restore(Expense expense) =>
      _db.into(_db.expenses).insert(expense);
}
