import 'package:flutter_test/flutter_test.dart';
import 'package:kilo_app/core/day.dart';

void main() {
  test('the Lima business day changes at 6am', () {
    expect(
      businessDay(DateTime.utc(2026, 11, 16, 10, 59)),
      DateTime.utc(2026, 11, 15),
    );
    expect(
      businessDay(DateTime.utc(2026, 11, 16, 11)),
      DateTime.utc(2026, 11, 16),
    );
  });

  test('days round-trip and add across months', () {
    final day = parseDay('2026-11-30');
    expect(formatDay(addDays(day, 1)), '2026-12-01');
    expect(formatDay(day), '2026-11-30');
  });
}
