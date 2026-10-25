import '../../../core/database/app_database.dart';
import '../../../core/format/money.dart';
import '../domain/expense_category.dart';

extension ExpenseLabels on Expense {
  /// "Logbook service" for a titled service record, else the category name.
  String get label => title ?? category.label;

  /// "$1.82/L · 37.6 L" for a fuel fill with litres; null otherwise.
  String? get fuelDetail {
    final l = litres;
    if (category != ExpenseCategory.fuel || l == null || l <= 0) return null;
    final perLitre = formatPricePerLitre(amountCents / l);
    return '$perLitre/L · ${l.toStringAsFixed(l >= 100 ? 0 : 1)} L';
  }
}
