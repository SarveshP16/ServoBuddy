import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/routes.dart';
import '../../../core/database/app_database.dart';
import '../../../core/format/numbers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/form_field_label.dart';
import '../../../core/widgets/header_button.dart';
import '../../../core/widgets/photo_field.dart';
import '../../../core/widgets/screen_header.dart';
import '../../garage/application/garage_provider.dart';
import '../application/vehicle_actions.dart';
import '../domain/body_type.dart';
import '../domain/fuel_type.dart';
import '../domain/vehicle_labels.dart';
import '../domain/vehicle_status.dart';
import 'widgets/delete_vehicle_dialog.dart';
import 'widgets/retire_vehicle_sheet.dart';

/// Add a car, or edit one when [vehicleId] is given.
class VehicleFormScreen extends ConsumerStatefulWidget {
  const VehicleFormScreen({super.key, this.vehicleId});

  final int? vehicleId;

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _odometer = TextEditingController();
  final _rego = TextEditingController();

  var _bodyType = BodyType.sedan;
  var _fuelType = FuelType.e10;
  String? _photoPath;
  DateTime? _regoExpiry;
  DateTime? _insuranceExpiry;
  bool _saving = false;

  Vehicle? _original;

  bool get _editing => widget.vehicleId != null;

  @override
  void initState() {
    super.initState();
    final id = widget.vehicleId;
    if (id == null) return;
    final garage = ref.read(garageProvider);
    final v = garage.vehicle(id);
    if (v == null) return;
    _original = v;
    _make.text = v.make;
    _model.text = v.model;
    _year.text = '${v.year}';
    final km = garage.odometerOf(id);
    if (km != null) _odometer.text = formatInt(km);
    _rego.text = v.rego ?? '';
    _bodyType = v.bodyType;
    _fuelType = v.fuelType;
    _photoPath = v.photoPath;
    _regoExpiry = v.regoExpiry;
    _insuranceExpiry = v.insuranceExpiry;
  }

  @override
  void dispose() {
    for (final c in [_make, _model, _year, _odometer, _rego]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _validateYear(String? v) {
    final year = int.tryParse(v?.trim() ?? '');
    final max = DateTime.now().year + 1;
    if (year == null || year < 1900 || year > max) {
      return 'Enter a year between 1900 and $max';
    }
    return null;
  }

  String? _validateOdometer(String? v) =>
      parseInt(v ?? '') == null ? 'Enter the km on the odometer' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final rego = _rego.text.trim().toUpperCase();
    final draft = VehicleDraft(
      make: _make.text.trim(),
      model: _model.text.trim(),
      year: int.parse(_year.text.trim()),
      bodyType: _bodyType,
      fuelType: _fuelType,
      rego: rego.isEmpty ? null : rego,
      odometerKm: parseInt(_odometer.text)!,
      photoPath: _photoPath,
      regoExpiry: _regoExpiry,
      insuranceExpiry: _insuranceExpiry,
    );
    final actions = ref.read(vehicleActionsProvider);
    try {
      if (_original == null) {
        final id = await actions.create(draft);
        if (mounted) context.pushReplacement(AppRoutes.vehicle(id));
      } else {
        await actions.update(_original!, draft);
        if (mounted) context.pop();
      }
    } on Exception {
      if (mounted) {
        setState(() => _saving = false);
        showAppSnackBar(context, "Couldn't save the vehicle. Try again.");
      }
    }
  }

  Future<void> _delete() async {
    final v = _original!;
    final choice = await askDeleteVehicle(context, name: v.displayName);
    if (choice == null || !mounted) return;
    final actions = ref.read(vehicleActionsProvider);
    switch (choice) {
      case DeleteVehicleChoice.keepHistory:
        await actions.deleteKeepingHistory(v);
      case DeleteVehicleChoice.everything:
        await actions.delete(v);
    }
    if (!mounted) return;
    showAppSnackBar(
      context,
      choice == DeleteVehicleChoice.keepHistory
          ? '${v.displayName} deleted — its expenses are kept'
          : '${v.displayName} deleted',
    );
    context.go(AppRoutes.vehicles);
  }

  Future<void> _retire() async {
    final v = _original!;
    if (!await showRetireVehicleSheet(context, v) || !mounted) return;
    showAppSnackBar(context, '${v.displayName} moved to Sold / not in use');
    context.go(AppRoutes.vehicles);
  }

  Future<void> _restore() async {
    final v = _original!;
    await ref.read(vehicleActionsProvider).restore(v);
    if (!mounted) return;
    showAppSnackBar(context, '${v.displayName} is back in use');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isPrimary = _original?.isPrimary ?? false;
    final vehicleCount = ref.watch(garageProvider).vehicles.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: _editing ? 'Edit vehicle' : 'Add vehicle',
              leading: HeaderButton(
                icon: LucideIcons.x,
                tooltip: 'Close',
                onPressed: () => context.pop(),
              ),
              trailing: _editing
                  ? HeaderButton(
                      icon: LucideIcons.trash2,
                      tooltip: 'Delete vehicle',
                      onPressed: _delete,
                    )
                  : null,
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    const FormFieldLabel('Photo', top: 0),
                    PhotoField(
                      path: _photoPath,
                      addLabel: 'Add a photo (optional)',
                      onChanged: (p) => setState(() => _photoPath = p),
                    ),
                    const FormFieldLabel('Make'),
                    AppTextField(
                      controller: _make,
                      hint: 'Toyota',
                      textCapitalization: TextCapitalization.words,
                      validator: _required,
                      textInputAction: TextInputAction.next,
                    ),
                    const FormFieldLabel('Model'),
                    AppTextField(
                      controller: _model,
                      hint: 'Corolla',
                      textCapitalization: TextCapitalization.words,
                      validator: _required,
                      textInputAction: TextInputAction.next,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FormFieldLabel('Year'),
                              AppTextField(
                                controller: _year,
                                hint: '2019',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                validator: _validateYear,
                                textInputAction: TextInputAction.next,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FormFieldLabel('Odometer'),
                              AppTextField(
                                controller: _odometer,
                                hint: '42,180',
                                suffixText: 'km',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[\d,]'),
                                  ),
                                ],
                                validator: _validateOdometer,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const FormFieldLabel('Body type'),
                    ChoicePillGroup<BodyType>(
                      options: BodyType.values,
                      selected: _bodyType,
                      labelOf: (b) => b.label,
                      large: false,
                      onSelected: (b) => setState(() => _bodyType = b),
                    ),
                    const FormFieldLabel('Fuel'),
                    ChoicePillGroup<FuelType>(
                      options: FuelType.values,
                      selected: _fuelType,
                      labelOf: (f) => f.shortLabel,
                      large: false,
                      onSelected: (f) => setState(() => _fuelType = f),
                    ),
                    const FormFieldLabel('Rego plate'),
                    AppTextField(
                      controller: _rego,
                      hint: '7XY-2KL (optional)',
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const FormFieldLabel('Rego expires'),
                    DateField(
                      value: _regoExpiry,
                      placeholder: 'Optional — for a renewal reminder',
                      clearable: true,
                      onChanged: (d) => setState(() => _regoExpiry = d),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Also reminds you to buy the CTP green slip, and to get '
                        'a pink slip if the car is over 5 years old.',
                        style: AppText.sub.copyWith(color: c.muted),
                      ),
                    ),
                    const FormFieldLabel('Insurance renews'),
                    DateField(
                      value: _insuranceExpiry,
                      placeholder: 'Optional — for a renewal reminder',
                      clearable: true,
                      onChanged: (d) => setState(() => _insuranceExpiry = d),
                    ),
                    // Only a car in use can be the main one.
                    if (_editing &&
                        vehicleCount > 1 &&
                        _original!.status == VehicleStatus.active) ...[
                      const SizedBox(height: 20),
                      _PrimaryToggle(
                        isPrimary: isPrimary,
                        onMakePrimary: () async {
                          await ref
                              .read(vehicleActionsProvider)
                              .setPrimary(_original!.id);
                          setState(
                            () => _original = _original!.copyWith(
                              isPrimary: true,
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Service schedules are set up from the vehicle page.',
                      style: AppText.sub.copyWith(color: c.muted),
                    ),
                    if (_editing) ...[
                      const SizedBox(height: 24),
                      _original!.status == VehicleStatus.retired
                          ? OutlineButton(
                              label: 'Put back in use',
                              onPressed: _restore,
                            )
                          : OutlineButton(
                              label: 'Mark as sold / not in use',
                              onPressed: _retire,
                            ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: PrimaryButton(
                label: _editing ? 'Save changes' : 'Save vehicle',
                busy: _saving,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryToggle extends StatelessWidget {
  const _PrimaryToggle({required this.isPrimary, required this.onMakePrimary});

  final bool isPrimary;
  final VoidCallback onMakePrimary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Main vehicle',
                style: AppText.cardTitle.copyWith(color: c.ink),
              ),
              const SizedBox(height: 2),
              Text(
                'Listed first, and its fuel type is used for Home prices.',
                style: AppText.sub.copyWith(color: c.muted),
              ),
            ],
          ),
        ),
        Switch(
          value: isPrimary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          // Turning it off would leave no main car; pick another instead.
          onChanged: isPrimary ? null : (_) => onMakePrimary(),
        ),
      ],
    );
  }
}
