import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/format/dates.dart';
import '../../../../core/format/numbers.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/calendar.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/date_field.dart';
import '../../../../core/widgets/form_field_label.dart';
import '../../../../core/widgets/icon_tile.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../garage/application/garage_provider.dart';
import '../../application/vehicle_actions.dart';
import '../../domain/wear_parts.dart';

/// "Tyres & battery": how old each is and when to replace it. Fitting dates
/// are set here by hand (they're often part of a service bill) or come from
/// a "Tyres" / "Battery" expense.
class WearPartsCard extends ConsumerWidget {
  const WearPartsCard({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final garage = ref.watch(garageProvider);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'TYRES & BATTERY',
            style: AppText.eyebrow.copyWith(color: c.primaryText),
          ),
          for (final part in WearPart.values)
            _PartRow(
              part: part,
              age: partAgeFor(
                vehicle,
                part,
                today: garage.today,
                currentKm: garage.odometerOf(vehicle.id),
                kmPerDay: garage.kmPerDayOf(vehicle.id),
              ),
              today: garage.today,
              onEdit: () => showWearPartSheet(context, vehicle, part),
            ),
        ],
      ),
    );
  }
}

class _PartRow extends StatelessWidget {
  const _PartRow({
    required this.part,
    required this.age,
    required this.today,
    required this.onEdit,
  });

  final WearPart part;
  final PartAge? age;
  final DateTime today;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final a = age;
    final lines = a == null
        ? [
            part == WearPart.tyres
                ? 'Not recorded. When were they fitted?'
                : 'Not recorded. When was it fitted?',
          ]
        : [
            'Fitted ${formatDate(a.fitted)} · '
                '${a.ageDays <= 0 ? 'just fitted' : '${formatAge(a.fitted, today)} old'}',
            [
              'Replace by ${formatMonth(a.replaceBy)}',
              if (a.replaceAtKm != null) 'or at ${formatKm(a.replaceAtKm!)}',
            ].join(' '),
          ];
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          IconTile(
            icon: part == WearPart.tyres
                ? LucideIcons.circleDot
                : LucideIcons.batteryMedium,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      part.label,
                      style: AppText.cardTitle.copyWith(color: c.ink),
                    ),
                    if (a != null && a.status != WearStatus.ok) ...[
                      const SizedBox(width: 8),
                      StatusBadge(
                        label: a.status == WearStatus.due
                            ? 'Replace now'
                            : 'Replace soon',
                      ),
                    ],
                  ],
                ),
                for (final l in lines)
                  Text(l, style: AppText.sub.copyWith(color: c.muted)),
              ],
            ),
          ),
          TextButton(
            onPressed: onEdit,
            child: Text(a == null ? 'Set' : 'Edit'),
          ),
        ],
      ),
    );
  }
}

/// When [part] went on, and for tyres the odometer then.
Future<void> showWearPartSheet(
  BuildContext context,
  Vehicle vehicle,
  WearPart part,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _WearPartSheet(vehicle: vehicle, part: part),
);

class _WearPartSheet extends ConsumerStatefulWidget {
  const _WearPartSheet({required this.vehicle, required this.part});

  final Vehicle vehicle;
  final WearPart part;

  @override
  ConsumerState<_WearPartSheet> createState() => _WearPartSheetState();
}

class _WearPartSheetState extends ConsumerState<_WearPartSheet> {
  late DateTime? _fitted = fittedDate(widget.vehicle, widget.part);
  late final _km = TextEditingController(
    text: widget.vehicle.tyresFittedKm == null
        ? ''
        : formatInt(widget.vehicle.tyresFittedKm!),
  );

  bool get _tyres => widget.part == WearPart.tyres;

  @override
  void dispose() {
    _km.dispose();
    super.dispose();
  }

  Future<void> _save(DateTime? fitted) async {
    await ref
        .read(vehicleActionsProvider)
        .recordFitting(
          widget.vehicle.id,
          widget.part,
          fitted,
          km: _tyres ? parseInt(_km.text) : null,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final today = dateOnly(ref.read(clockProvider)());
    final had = fittedDate(widget.vehicle, widget.part) != null;
    final name = widget.part.label.toLowerCase();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          Text(
            _tyres
                ? 'When were the tyres fitted?'
                : 'When was the battery fitted?',
            style: AppText.section.copyWith(color: c.ink),
          ),
          const SizedBox(height: 6),
          Text(
            _tyres
                ? 'Tyres are usually replaced about every 5 years or '
                      '40,000 km, whichever comes first.'
                : 'Car batteries usually last 3 to 5 years. ServoBuddy '
                      'suggests replacing at 4.',
            style: AppText.sub.copyWith(color: c.muted),
          ),
          const FormFieldLabel('Fitted on'),
          DateField(
            value: _fitted,
            placeholder: 'Pick the date',
            lastDate: today,
            onChanged: (d) => setState(() => _fitted = d),
          ),
          if (_tyres) ...[
            const FormFieldLabel('Odometer then (optional)'),
            AppTextField(
              controller: _km,
              hint: 'For the 40,000 km limit',
              suffixText: 'km',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,]')),
              ],
            ),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Save',
            onPressed: _fitted == null ? null : () => _save(_fitted),
          ),
          if (had)
            TextButton(
              onPressed: () => _save(null),
              child: Text('Forget the $name date'),
            ),
        ],
      ),
    );
  }
}
