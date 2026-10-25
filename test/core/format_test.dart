import 'package:flutter_test/flutter_test.dart';
import 'package:servobuddy/core/format/dates.dart';
import 'package:servobuddy/core/format/money.dart';
import 'package:servobuddy/core/format/numbers.dart';

void main() {
  group('money', () {
    test('drops cents only on whole dollars, as mocked', () {
      expect(formatMoney(124000), r'$1,240');
      expect(formatMoney(6840), r'$68.40');
      expect(formatMoney(22000), r'$220');
      expect(formatMoney(5), r'$0.05');
    });

    test('parses typed amounts to cents', () {
      expect(parseMoneyToCents('68.4'), 6840);
      expect(parseMoneyToCents('68.40'), 6840);
      expect(parseMoneyToCents(r'$1,240'), 124000);
      expect(parseMoneyToCents('0.05'), 5);
      expect(parseMoneyToCents('12.'), 1200);
      expect(parseMoneyToCents(''), isNull);
      expect(parseMoneyToCents('1.234'), isNull);
      expect(parseMoneyToCents('abc'), isNull);
      expect(parseMoneyToCents('-5'), isNull);
    });

    test('shows fuel prices in dollars per litre', () {
      expect(formatPricePerLitre(162.0), r'$1.62');
      expect(formatPricePerLitre(162.9), r'$1.63');
    });
  });

  group('numbers', () {
    test('formats km with grouping', () {
      expect(formatKm(42180), '42,180 km');
    });

    test('parses odometer and litre inputs', () {
      expect(parseInt('42,180'), 42180);
      expect(parseInt('4.2'), isNull);
      expect(parseDecimal('45.2'), 45.2);
      expect(parseDecimal('x'), isNull);
    });
  });

  group('dates', () {
    final now = DateTime(2026, 9, 23, 14);

    test('relative day', () {
      expect(formatRelativeDay(DateTime(2026, 9, 23), now), 'Today');
      expect(formatRelativeDay(DateTime(2026, 9, 22), now), 'Yesterday');
      expect(formatRelativeDay(DateTime(2026, 9, 12), now), '12 Sep 2026');
    });

    test('approximate spans', () {
      expect(formatApproxSpan(0), 'today');
      expect(formatApproxSpan(5), '5 days');
      expect(formatApproxSpan(21), '3 weeks');
      expect(formatApproxSpan(90), '3 months');
    });

    test('greeting follows the clock', () {
      expect(greetingFor(DateTime(2026, 1, 1, 8)), 'Good morning');
      expect(greetingFor(DateTime(2026, 1, 1, 14)), 'Good afternoon');
      expect(greetingFor(DateTime(2026, 1, 1, 19)), 'Good evening');
    });
  });
}
