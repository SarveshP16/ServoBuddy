import 'package:flutter_test/flutter_test.dart';
import 'package:servobuddy/core/utils/calendar.dart';

void main() {
  group('addDays', () {
    test('stays on midnight across the NSW daylight-saving start', () {
      // Clocks go forward on 4 Oct 2026 in Sydney; Duration maths would
      // land at 01:00 on a device in that zone. Field maths never does.
      final d = addDays(DateTime(2026, 10, 1), 7);
      expect(d, DateTime(2026, 10, 8));
      expect(d.hour, 0);
    });

    test('rolls over month and year ends', () {
      expect(addDays(DateTime(2026, 12, 30), 3), DateTime(2027, 1, 2));
      expect(addDays(DateTime(2026, 3, 1), -1), DateTime(2026, 2, 28));
    });
  });

  group('addMonths', () {
    test('keeps the day of month', () {
      expect(addMonths(DateTime(2026, 3, 15), 12), DateTime(2027, 3, 15));
    });

    test('clamps to the end of shorter months', () {
      expect(addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
      expect(addMonths(DateTime(2027, 12, 31), 2), DateTime(2028, 2, 29));
      expect(addMonths(DateTime(2026, 8, 31), 1), DateTime(2026, 9, 30));
    });

    test('goes backwards too', () {
      expect(addMonths(DateTime(2026, 3, 31), -1), DateTime(2026, 2, 28));
    });
  });

  test('daysBetween counts calendar days regardless of time and DST', () {
    expect(daysBetween(DateTime(2026, 10, 1, 23), DateTime(2026, 10, 8, 1)), 7);
    expect(daysBetween(DateTime(2026, 10, 8), DateTime(2026, 10, 1)), -7);
    expect(daysBetween(DateTime(2026, 4, 1), DateTime(2026, 4, 1, 12)), 0);
  });
}
