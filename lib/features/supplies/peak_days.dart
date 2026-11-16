import '../../core/formatters.dart';
import '../../data/models/forecast_day.dart';

class PeakDays {
  const PeakDays();

  String? sentence(List<ForecastDay> week) {
    final busy = [
      for (final day in week)
        if (day.amount > 0) day,
    ]..sort((a, b) => b.amount.compareTo(a.amount));
    if (busy.isEmpty) return null;
    final names = [
      for (final day in busy.take(2)) weekdayLong[day.day.weekday - 1],
    ];
    return 'Se usa más el ${names.join(' y el ')}.';
  }
}
