import '../../core/day.dart';
import '../json.dart';

class ForecastDay {
  const ForecastDay({required this.day, required this.amount});

  factory ForecastDay.fromJson(Json json) => ForecastDay(
    day: parseDay(json['day']! as String),
    amount: decodeDouble(json['amount']),
  );

  final DateTime day;
  final double amount;
}
