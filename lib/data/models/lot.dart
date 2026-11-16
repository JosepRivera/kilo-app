import '../../core/day.dart';
import '../json.dart';

class Lot {
  const Lot({
    required this.id,
    required this.purchasedOn,
    required this.expiresOn,
    required this.remaining,
    required this.daysLeft,
  });

  factory Lot.fromJson(Json json) => Lot(
    id: json['id']! as String,
    purchasedOn: parseDay(json['purchasedOn']! as String),
    expiresOn: parseDay(json['expiresOn']! as String),
    remaining: decodeDouble(json['remaining']),
    daysLeft: decodeInt(json['daysLeft']),
  );

  final String id;
  final DateTime purchasedOn;
  final DateTime expiresOn;
  final double remaining;
  final int daysLeft;
}
