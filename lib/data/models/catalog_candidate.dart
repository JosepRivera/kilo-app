import '../json.dart';

class CatalogCandidate {
  const CatalogCandidate({
    required this.supplyId,
    required this.name,
    required this.unit,
    required this.category,
  });

  factory CatalogCandidate.fromJson(Json json) => CatalogCandidate(
    supplyId: json['supplyId'] as String?,
    name: json['name']! as String,
    unit: json['unit']! as String,
    category: json['category'] as String?,
  );

  final String? supplyId;
  final String name;
  final String unit;
  final String? category;
}
