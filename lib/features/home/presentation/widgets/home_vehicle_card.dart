import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/format/numbers.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../vehicles/domain/vehicle_labels.dart';
import '../../../vehicles/presentation/widgets/vehicle_image.dart';

/// One card in Home's sideways vehicle strip.
class HomeVehicleCard extends StatelessWidget {
  const HomeVehicleCard({
    super.key,
    required this.vehicle,
    required this.odometerKm,
    required this.onTap,
  });

  static const width = 161.0;

  final Vehicle vehicle;
  final int? odometerKm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: width,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VehicleImage(
              photoPath: vehicle.photoPath,
              height: 88,
              radius: 12,
              glyphSize: 46,
            ),
            const SizedBox(height: 8),
            Text(
              vehicle.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.cardTitle.copyWith(color: c.ink, fontSize: 15),
            ),
            const SizedBox(height: 1),
            Text(
              [
                '${vehicle.year}',
                if (odometerKm != null) formatKm(odometerKm!),
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.sub.copyWith(color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}
