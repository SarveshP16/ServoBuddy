/// Starting points offered when setting up a car's service schedule. Typical
/// Australian manufacturer intervals; every value is editable.
class SchedulePreset {
  const SchedulePreset(this.name, {this.km, this.months});

  final String name;
  final int? km;
  final int? months;
}

const schedulePresets = [
  SchedulePreset('Logbook service', km: 15000, months: 12),
  SchedulePreset('Oil change', km: 10000, months: 12),
  SchedulePreset('Tyre rotation', km: 10000, months: 6),
  SchedulePreset('Brake check', km: 20000, months: 12),
  SchedulePreset('Air filter', km: 30000, months: 24),
  SchedulePreset('Coolant flush', km: 40000, months: 24),
  SchedulePreset('Timing belt', km: 100000, months: 60),
];
