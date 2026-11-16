import '../json.dart';

class SupplyCategory {
  const SupplyCategory({
    required this.id,
    required this.name,
    required this.purchaseIntervalDays,
    required this.monthlySpend,
    required this.critical,
  });

  factory SupplyCategory.fromJson(Json json) => SupplyCategory(
    id: json['id']! as String,
    name: json['name']! as String,
    purchaseIntervalDays: decodeInt(json['purchaseIntervalDays']),
    monthlySpend: decodeDouble(json['monthlySpend']),
    critical: json['critical']! as bool,
  );

  final String id;
  final String name;
  final int purchaseIntervalDays;
  final double monthlySpend;
  final bool critical;
}
