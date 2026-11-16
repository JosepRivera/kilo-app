import '../../data/models/supply.dart';
import '../../data/models/supply_category.dart';

class SuppliesCatalog {
  const SuppliesCatalog({required this.supplies, required this.categories});

  final List<Supply> supplies;
  final List<SupplyCategory> categories;
}
