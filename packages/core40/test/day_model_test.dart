import 'package:core40/core40.dart';
import 'package:test/test.dart';

void main() {
  test('wake day key is the calendar date of waking', () {
    final wake = DateTime(2026, 1, 2, 8, 15);
    expect(dayKeyForWake(wake), DateTime(2026, 1, 2));
  });

  test('night belongs to the morning it ends with', () {
    // Sleep 23:40 -> 07:30 next day is booked on the wake day.
    final sleepEnd = DateTime(2026, 1, 2, 7, 30);
    expect(sleepDayKey(sleepEnd), DateTime(2026, 1, 2));
  });

  test('daysBetween counts whole wake days', () {
    expect(
      daysBetween(DateTime(2026, 1, 1, 22, 0), DateTime(2026, 1, 15, 6, 0)),
      14,
    );
  });
}
