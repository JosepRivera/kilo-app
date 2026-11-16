import '../json.dart';

class NewSupply {
  const NewSupply({
    required this.name,
    this.unit,
    this.categoryId,
    this.shelfLifeDays,
    this.referencePrice,
  });

  final String name;
  final String? unit;
  final String? categoryId;
  final int? shelfLifeDays;
  final double? referencePrice;

  Json toJson() => {
    'name': name,
    'unit': ?unit,
    'categoryId': ?categoryId,
    'shelfLifeDays': ?shelfLifeDays,
    'referencePrice': ?referencePrice,
  };
}
