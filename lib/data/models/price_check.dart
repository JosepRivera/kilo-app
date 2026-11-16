import '../json.dart';

class PriceCheck {
  const PriceCheck({
    required this.usual,
    required this.low,
    required this.high,
  });

  factory PriceCheck.fromJson(Json json) => PriceCheck(
    usual: decodeDouble(json['usual']),
    low: decodeDouble(json['low']),
    high: decodeDouble(json['high']),
  );

  final double usual;
  final double low;
  final double high;
}
