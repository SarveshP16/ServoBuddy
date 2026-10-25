import 'package:intl/intl.dart';

final _grouped = NumberFormat.decimalPattern('en_AU');

/// "42,180 km".
String formatKm(int km) => '${_grouped.format(km)} km';

/// "42,180".
String formatInt(int n) => _grouped.format(n);

/// Parses "42,180" or "42180" to an int; null if it isn't a whole number.
int? parseInt(String input) {
  final cleaned = input.replaceAll(RegExp(r'[\s,]'), '');
  if (!RegExp(r'^\d+$').hasMatch(cleaned)) return null;
  return int.tryParse(cleaned);
}

/// Parses "45.2" litres; null if it isn't a positive number.
double? parseDecimal(String input) {
  final cleaned = input.replaceAll(RegExp(r'[\s,]'), '');
  final value = double.tryParse(cleaned);
  if (value == null || value.isNaN || value < 0) return null;
  return value;
}
