import 'package:drift/drift.dart' show Value;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../domain/expense_category.dart';

/// What the expense form collects.
class ExpenseDraft {
  const ExpenseDraft({
    required this.vehicleId,
    required this.category,
    required this.amountCents,
    required this.date,
    required this.title,
    required this.notes,
    required this.receiptPath,
    required this.litres,
    required this.fullTank,
    required this.odometerKm,
    required this.scheduleId,
  });

  final int vehicleId;
  final ExpenseCategory category;
  final int amountCents;
  final DateTime date;
  final String? title;
  final String? notes;

  /// A stored receipt, or a just-picked temp file to import.
  final String? receiptPath;
  final double? litres;
  final bool fullTank;
  final int? odometerKm;
  final int? scheduleId;
}

final expenseActionsProvider = Provider<ExpenseActions>(ExpenseActions.new);

/// Expense writes that also touch receipt files.
class ExpenseActions {
  ExpenseActions(this._ref);

  final Ref _ref;

  Future<void> create(ExpenseDraft d) async {
    final receipt = d.receiptPath == null
        ? null
        : await _ref
              .read(imageStoreProvider)
              .import(d.receiptPath!, folder: 'receipts');
    await _ref
        .read(expenseRepositoryProvider)
        .add(
          ExpensesCompanion.insert(
            vehicleId: d.vehicleId,
            category: d.category,
            amountCents: d.amountCents,
            date: d.date,
            title: Value(d.title),
            notes: Value(d.notes),
            receiptPath: Value(receipt),
            litres: Value(d.litres),
            fullTank: Value(d.fullTank),
            odometerKm: Value(d.odometerKm),
            scheduleId: Value(d.scheduleId),
          ),
        );
  }

  Future<void> update(Expense original, ExpenseDraft d) async {
    final images = _ref.read(imageStoreProvider);
    var receipt = original.receiptPath;
    if (d.receiptPath != original.receiptPath) {
      receipt = d.receiptPath == null
          ? null
          : await images.import(d.receiptPath!, folder: 'receipts');
      await images.delete(original.receiptPath);
    }
    await _ref
        .read(expenseRepositoryProvider)
        .save(
          original.copyWith(
            vehicleId: d.vehicleId,
            category: d.category,
            amountCents: d.amountCents,
            date: d.date,
            title: Value(d.title),
            notes: Value(d.notes),
            receiptPath: Value(receipt),
            litres: Value(d.litres),
            fullTank: d.fullTank,
            odometerKm: Value(d.odometerKm),
            scheduleId: Value(d.scheduleId),
          ),
        );
  }

  /// Deletes with an Undo toast. The receipt photo is only removed once the
  /// toast goes away without Undo, so Undo gets it back too.
  Future<void> deleteWithUndo(BuildContext context, Expense e) async {
    final repo = _ref.read(expenseRepositoryProvider);
    await repo.delete(e.id);
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      'Expense deleted',
      actionLabel: 'Undo',
      onAction: () => repo.restore(e),
      onDismissed: () => _ref.read(imageStoreProvider).delete(e.receiptPath),
    );
  }
}
