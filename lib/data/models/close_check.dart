import '../json.dart';

class CloseCheck {
  const CloseCheck({
    required this.base,
    required this.gapDays,
    required this.usual,
    required this.reviewBelow,
  });

  factory CloseCheck.fromJson(Json json) => CloseCheck(
    base: decodeDouble(json['base']),
    gapDays: decodeInt(json['gapDays']),
    usual: decodeDouble(json['usual']),
    reviewBelow: decodeDouble(json['reviewBelow']),
  );

  final double base;
  final int gapDays;
  final double usual;
  final double reviewBelow;
}
