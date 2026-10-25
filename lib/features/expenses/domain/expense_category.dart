/// Stored by name, so values can be added or reordered without a migration.
/// Declaration order is the order they're offered in.
enum ExpenseCategory {
  fuel('Fuel'),
  service('Service'),
  repairs('Repairs & parts'),
  rego('Rego'),
  insurance('Insurance'),
  tolls('Tolls'),
  parking('Parking'),
  carWash('Car wash'),
  other('Other');

  const ExpenseCategory(this.label);

  final String label;
}
