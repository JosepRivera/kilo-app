const _limaOffset = Duration(hours: 5);
const _dayStartsAt = Duration(hours: 6);

DateTime parseDay(String value) => DateTime.parse('${value}T00:00:00Z');

String formatDay(DateTime day) {
  final year = day.year.toString().padLeft(4, '0');
  final month = day.month.toString().padLeft(2, '0');
  final date = day.day.toString().padLeft(2, '0');
  return '$year-$month-$date';
}

DateTime addDays(DateTime day, int days) =>
    DateTime.utc(day.year, day.month, day.day + days);

DateTime businessDay(DateTime now) {
  final shifted = now.toUtc().subtract(_limaOffset + _dayStartsAt);
  return DateTime.utc(shifted.year, shifted.month, shifted.day);
}
