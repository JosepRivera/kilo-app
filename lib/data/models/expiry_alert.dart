import '../json.dart';
import 'expiring_lot.dart';
import 'supply.dart';

class ExpiryAlert {
  const ExpiryAlert({
    required this.supply,
    required this.daysLeft,
    required this.remaining,
    required this.lots,
  });

  factory ExpiryAlert.fromJson(Json json) => ExpiryAlert(
    supply: Supply.fromJson(json['supply']! as Json),
    daysLeft: decodeInt(json['daysLeft']),
    remaining: decodeDouble(json['remaining']),
    lots: decodeList(json['lots'], ExpiringLot.fromJson),
  );

  final Supply supply;
  final int daysLeft;
  final double remaining;
  final List<ExpiringLot> lots;
}
