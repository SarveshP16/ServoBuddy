import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/icon_tile.dart';
import '../../garage/application/garage_provider.dart';
import '../../vehicles/domain/vehicle_labels.dart';
import 'upcoming_items.dart';

Future<void> showUpcomingSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _UpcomingSheet(),
    );

class _UpcomingSheet extends ConsumerWidget {
  const _UpcomingSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final items = upcomingItems(ref.watch(garageProvider));
    final multiCar = ref.watch(garageProvider).vehicles.length > 1;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text('Coming up', style: AppText.section.copyWith(color: c.ink)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'Nothing scheduled. Add service reminders and rego or insurance '
              'dates on a vehicle to see them here.',
              style: AppText.body.copyWith(color: c.muted),
            ),
          for (final item in items) ...[
            AppCard(
              padding: const EdgeInsets.all(12),
              color: item.urgent ? c.warnTint : null,
              borderColor: item.urgent ? c.warnBorder : null,
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.vehicle(item.vehicle.id));
              },
              child: Row(
                children: [
                  IconTile(
                    icon: switch (item.kind) {
                      UpcomingKind.service => LucideIcons.wrench,
                      UpcomingKind.rego => LucideIcons.fileText,
                      UpcomingKind.insurance => LucideIcons.shieldCheck,
                      UpcomingKind.greenSlip => LucideIcons.fileCheck,
                      UpcomingKind.pinkSlip => LucideIcons.clipboardCheck,
                      UpcomingKind.tyres => LucideIcons.circleDot,
                      UpcomingKind.battery => LucideIcons.batteryMedium,
                    },
                    color: item.urgent ? c.warn : c.primary,
                    background: item.urgent ? c.warnTile : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          multiCar
                              ? '${item.title} — ${item.vehicle.shortName}'
                              : item.title,
                          style: AppText.cardTitle.copyWith(
                            color: item.urgent ? c.warnInk : c.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.detail,
                          style: AppText.sub.copyWith(
                            color: item.urgent ? c.warnMuted : c.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
