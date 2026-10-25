import 'package:intl/intl.dart';

final _whole = NumberFormat.currency(
  locale: 'en_AU',
  symbol: r'$',
  decimalDigits: 0,
);
final _cents = NumberFormat.currency(
  locale: 'en_AU',
  symbol: r'$',
  decimalDigits: 2,
);

/// "$1,240" for whole dollars, "$68.40" otherwise — as the mockups show it.
String formatMoney(int cents) =>
    cents % 100 == 0 ? _whole.format(cents ~/ 100) : _cents.format(cents / 100);

/// Always two decimals: "$68.40", "$220.00". For editable fields.
String formatMoneyExact(int cents) => _cents.format(cents / 100);

/// Parses what someone typed into an amount field ("68.4", "$1,240") to cents.
/// Returns null for anything that isn't a non-negative amount.
int? parseMoneyToCents(String input) {
  final cleaned = input.replaceAll(RegExp(r'[\s$,]'), '');
  if (cleaned.isEmpty) return null;
  if (!RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(cleaned)) return null;
  final parts = cleaned.split('.');
  final dollars = int.parse(parts[0]);
  final centsText = parts.length > 1 ? parts[1].padRight(2, '0') : '00';
  return dollars * 100 + int.parse(centsText);
}

/// Fuel price in dollars per litre from cents per litre: 162.9 → "$1.63".
String formatPricePerLitre(double centsPerLitre) =>
    _cents.format(centsPerLitre / 100);
