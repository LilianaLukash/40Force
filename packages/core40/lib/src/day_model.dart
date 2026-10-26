/// Day model: a day starts at wake-up; the night belongs to the morning
/// it ends with. The day key is the calendar date of waking up.

DateTime dayKeyForWake(DateTime wake) =>
    DateTime(wake.year, wake.month, wake.day);

/// A sleep interval is booked on the day of its ending wake-up.
DateTime sleepDayKey(DateTime sleepEnd) => dayKeyForWake(sleepEnd);

/// Whole days between two timestamps, by wake-day keys.
int daysBetween(DateTime from, DateTime to) =>
    dayKeyForWake(to).difference(dayKeyForWake(from)).inDays;
