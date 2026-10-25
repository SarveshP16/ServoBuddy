import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/sign_panel.dart';
import '../../../vehicles/domain/vehicle_labels.dart';

/// Home's road sign for the main car: its name and plate, and a yellow
/// strip saying where its servicing stands.
class MainVehiclePanel extends StatelessWidget {
  const MainVehiclePanel({
    super.key,
    required this.vehicle,
    required this.serviceTitle,
    required this.serviceDetail,
    required this.onTap,
    required this.onServiceTap,
  });

  final Vehicle vehicle;
  final String serviceTitle;
  final String serviceDetail;
  final VoidCallback onTap;
  final VoidCallback onServiceTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SignPanel(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MAIN VEHICLE',
                      style: AppText.tiny.copyWith(
                        color: c.onHero.withValues(alpha: 0.85),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicle.displayName.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.display.copyWith(color: c.onHero),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${vehicle.year} · ${vehicle.bodyType.label} · '
                      '${vehicle.fuelType.shortLabel}',
                      style: AppText.body.copyWith(
                        color: c.onHero.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              PlateBadge(rego: vehicle.rego),
            ],
          ),
          const SizedBox(height: 14),
          Material(
            color: c.highlight,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onServiceTap,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Row(
                  children: [
                    Icon(LucideIcons.wrench, size: 20, color: c.onHighlight),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            serviceTitle,
                            style: AppText.cardTitle.copyWith(
                              color: c.onHighlight,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (serviceDetail.isNotEmpty)
                            Text(
                              serviceDetail,
                              style: AppText.sub.copyWith(color: c.onHighlight),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: c.onHighlight,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
