import 'package:flutter/material.dart';

import '../../../../core/format/dates.dart';
import '../../../../core/format/numbers.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/calendar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../expenses/domain/fuel_economy.dart';

/// Odometer, economy and renewal dates in a compact grid. Only rows with
/// something to say are shown.
class VehicleFactsCard extends StatelessWidget {
  const VehicleFactsCard({
    super.key,
    required this.odometerKm,
    required this.fuel,
    required this.regoExpiry,
    required this.insuranceExpiry,
    required this.today,
    this.pinkSlipFrom,
  });

  final int? odometerKm;
  final FuelStats fuel;
  final DateTime? regoExpiry;
  final DateTime? insuranceExpiry;
  final DateTime today;

  /// When the pink-slip window opens, for cars that need one.
  final DateTime? pinkSlipFrom;

  @override
  Widget build(BuildContext context) {
    final economy = fuel.litresPer100Km;
    final perKm = fuel.centsPerKm;
    final facts = [
      if (odometerKm != null) ('Odometer', formatKm(odometerKm!), false),
      if (economy != null)
        ('Economy', '${economy.toStringAsFixed(1)} L/100km', false),
      if (perKm != null)
        ('Fuel cost', '${perKm.toStringAsFixed(1)}¢/km', false),
      if (regoExpiry != null) _renewal('Rego', regoExpiry!),
      if (regoExpiry != null) ('Green slip by', formatDate(regoExpiry!), false),
      if (regoExpiry != null && pinkSlipFrom != null)
        ('Pink slip from', formatDate(pinkSlipFrom!), false),
      if (insuranceExpiry != null) _renewal('Insurance', insuranceExpiry!),
    ];
    if (facts.isEmpty) return const SizedBox.shrink();

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          for (final (i, (label, value, warn)) in facts.indexed) ...[
            if (i > 0) const SizedBox(height: 8),
            _FactRow(label: label, value: value, warn: warn),
          ],
        ],
      ),
    );
  }

  (String, String, bool) _renewal(String what, DateTime expiry) {
    final days = daysBetween(today, expiry);
    if (days < 0) return ('$what expired', formatDate(expiry), true);
    return ('$what expires', formatDate(expiry), days <= 30);
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.label,
    required this.value,
    required this.warn,
  });

  final String label;
  final String value;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: Text(label, style: AppText.sub.copyWith(color: c.muted)),
        ),
        Text(
          value,
          style: AppText.label.copyWith(color: warn ? c.warn : c.ink),
        ),
      ],
    );
  }
}
