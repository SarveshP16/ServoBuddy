import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/format/numbers.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/vehicle_alert.dart';
import '../../domain/vehicle_labels.dart';
import 'vehicle_image.dart';

/// A card in the Vehicles list: photo, name, year · km, alert badge.
class VehicleRow extends StatelessWidget {
  const VehicleRow({
    super.key,
    required this.vehicle,
    required this.odometerKm,
    required this.alert,
    required this.onTap,
    this.statusLabel,
  });

  final Vehicle vehicle;
  final int? odometerKm;
  final VehicleAlert? alert;
  final VoidCallback onTap;

  /// A neutral tag instead of an alert ("Sold 12 Aug 2026").
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          VehicleImage(
            photoPath: vehicle.photoPath,
            width: 64,
            height: 64,
            radius: 14,
            glyphSize: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardTitle.copyWith(
                    color: c.ink,
                    fontSize: 16.5,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      [
                        '${vehicle.year}',
                        if (odometerKm != null) formatKm(odometerKm!),
                      ].join(' · '),
                      style: AppText.sub.copyWith(color: c.muted),
                    ),
                    if (alert != null) StatusBadge(label: alert!.label),
                    if (statusLabel != null)
                      StatusBadge(
                        label: statusLabel!,
                        background: c.track,
                        foreground: c.muted,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(LucideIcons.chevronRight, size: 20, color: c.faint),
        ],
      ),
    );
  }
}
