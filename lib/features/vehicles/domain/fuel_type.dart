/// What a vehicle runs on.
enum FuelType {
  e10('E10', 'E10'),
  u91('Unleaded 91', 'U91'),
  p95('Premium 95', 'P95'),
  p98('Premium 98', 'P98'),
  diesel('Diesel', 'Diesel'),
  premiumDiesel('Premium Diesel', 'Prem. Diesel'),
  lpg('LPG', 'LPG');

  const FuelType(this.label, this.shortLabel);

  final String label;

  /// Used where space is tight (chips on the vehicle form).
  final String shortLabel;
}
