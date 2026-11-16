import '../../core/day.dart';
import '../json.dart';
import 'recent_day_kind.dart';

class RecentDay {
  const RecentDay({
    required this.day,
    required this.amount,
    required this.kind,
  });

  factory RecentDay.fromJson(Json json) => RecentDay(
    day: parseDay(json['day']! as String),
    amount: decodeDouble(json['amount']),
    kind: RecentDayKind.values.byName(json['kind']! as String),
  );

  final DateTime day;
  final double amount;
  final RecentDayKind kind;
}
