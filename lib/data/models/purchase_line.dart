import '../../core/day.dart';
import '../json.dart';

class PurchaseLine {
  const PurchaseLine({
    required this.supplyId,
    required this.quantity,
    required this.cost,
    required this.expiresOn,
  });

  final String supplyId;
  final double quantity;
  final double cost;
  final DateTime expiresOn;

  Json toJson() => {
    'supplyId': supplyId,
    'quantity': quantity,
    'cost': cost,
    'expiresOn': formatDay(expiresOn),
  };
}
