import '../../core/day.dart';
import '../json.dart';

class ExpiringLot {
  const ExpiringLot({
    required this.purchasedOn,
    required this.remaining,
    required this.daysLeft,
  });

  factory ExpiringLot.fromJson(Json json) => ExpiringLot(
    purchasedOn: parseDay(json['purchasedOn']! as String),
    remaining: decodeDouble(json['remaining']),
    daysLeft: decodeInt(json['daysLeft']),
  );

  final DateTime purchasedOn;
  final double remaining;
  final int daysLeft;
}
