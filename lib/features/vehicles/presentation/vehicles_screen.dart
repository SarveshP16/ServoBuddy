import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/routes.dart';
import '../../../core/format/dates.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/car_glyph.dart';
import '../../../core/widgets/dashed_add_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/header_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/section_header.dart';
import '../../garage/application/garage_provider.dart';
import 'widgets/vehicle_row.dart';

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final garage = ref.watch(garageProvider);
    final loaded = ref.watch(garageLoadedProvider);
    void add() => context.push(AppRoutes.newVehicle);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // A tab, so no back arrow (the mockup's was a mistake); the spacer
          // keeps the title centred against the add button.
          ScreenHeader(
            title: 'Vehicles',
            centerTitle: false,
            trailing: HeaderButton(
              icon: LucideIcons.plus,
              tooltip: 'Add vehicle',
              filled: true,
              onPressed: add,
            ),
          ),
          Expanded(
            child: !loaded
                ? const SizedBox.shrink()
                : garage.isEmpty && garage.retiredVehicles.isEmpty
                ? Center(
                    child: EmptyState(
                      icon: CarGlyph(size: 56, color: context.colors.primary),
                      title: 'No vehicles yet',
                      message:
                          'Add your car to track fuel, services and renewals.',
                      action: PrimaryButton(
                        label: 'Add your first vehicle',
                        onPressed: add,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      for (final v in garage.vehicles) ...[
                        VehicleRow(
                          vehicle: v,
                          odometerKm: garage.odometerOf(v.id),
                          alert: garage.alertOf(v),
                          onTap: () => context.push(AppRoutes.vehicle(v.id)),
                        ),
                        const SizedBox(height: 10),
                      ],
                      DashedAddButton(label: 'Add vehicle', onTap: add),
                      if (garage.retiredVehicles.isNotEmpty) ...[
                        const SectionHeader(
                          title: 'Sold / not in use',
                          padding: EdgeInsets.only(top: 28, bottom: 12),
                        ),
                        for (final v in garage.retiredVehicles) ...[
                          Opacity(
                            opacity: 0.75,
                            child: VehicleRow(
                              vehicle: v,
                              odometerKm: garage.odometerOf(v.id),
                              alert: null,
                              statusLabel: v.soldDate == null
                                  ? 'Not in use'
                                  : 'Sold ${formatDate(v.soldDate!)}',
                              onTap: () =>
                                  context.push(AppRoutes.vehicle(v.id)),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
