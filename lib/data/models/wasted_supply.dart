import '../json.dart';
import 'supply.dart';

class WastedSupply {
  const WastedSupply({required this.supply, required this.soles});

  factory WastedSupply.fromJson(Json json) => WastedSupply(
    supply: Supply.fromJson(json['supply']! as Json),
    soles: decodeDouble(json['soles']),
  );

  final Supply supply;
  final double soles;
}
