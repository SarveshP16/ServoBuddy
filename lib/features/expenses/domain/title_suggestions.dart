import 'expense_category.dart';

extension TitleSuggestions on ExpenseCategory {
  /// One-tap titles offered under the title field. A starting point: any
  /// title can be typed instead.
  List<String> get titleSuggestions => switch (this) {
    ExpenseCategory.fuel => const ['E10', 'U91', 'P95', 'P98', 'Diesel'],
    ExpenseCategory.service => const [
      'Logbook service',
      'Oil and filter',
      'Minor service',
      'Major service',
      'Brake service',
    ],
    ExpenseCategory.repairs => const [
      'Battery',
      'Tyres',
      'Brake pads',
      'Rotors',
      'Wiper blades',
      'Globe / light',
      'Alternator',
      'Spark plugs',
    ],
    ExpenseCategory.rego => const [
      'Rego renewal',
      'CTP green slip',
      'Pink slip inspection',
    ],
    ExpenseCategory.insurance => const [
      'Comprehensive',
      'Third party property',
    ],
    ExpenseCategory.tolls => const ['Linkt top-up', 'E-toll account'],
    ExpenseCategory.parking => const ['Street parking', 'Car park'],
    ExpenseCategory.carWash => const ['Wash', 'Detail'],
    ExpenseCategory.other => const [
      'Fine',
      'Accessories',
      'Roadside assist membership',
    ],
  };
}
