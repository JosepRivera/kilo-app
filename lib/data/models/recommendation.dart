import '../json.dart';

class Recommendation {
  const Recommendation({
    required this.toBuy,
    required this.onHand,
    required this.demand,
    required this.buffer,
    required this.horizonDays,
    required this.typicalError,
  });

  factory Recommendation.fromJson(Json json) => Recommendation(
    toBuy: decodeDouble(json['toBuy']),
    onHand: decodeDouble(json['onHand']),
    demand: decodeDouble(json['demand']),
    buffer: decodeDouble(json['buffer']),
    horizonDays: decodeInt(json['horizonDays']),
    typicalError: decodeDouble(json['typicalError']),
  );

  final double toBuy;
  final double onHand;
  final double demand;
  final double buffer;
  final int horizonDays;
  final double typicalError;

  double get needed => demand + buffer;

  double get coveredFraction => needed > 0 ? onHand / needed : 1;
}
