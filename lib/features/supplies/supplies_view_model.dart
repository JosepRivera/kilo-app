import '../../core/loadable.dart';
import '../../data/models/supply.dart';
import '../../data/repositories/restaurant_repository.dart';
import '../../data/repositories/supply_repository.dart';
import 'supplies_catalog.dart';
import 'supply_section.dart';
import 'supply_sections.dart';

class SuppliesViewModel extends Loadable<SuppliesCatalog> {
  SuppliesViewModel({
    required this._supplies,
    required this._restaurants,
    super.refreshOn,
  });

  static const _sections = SupplySections();

  final SupplyRepository _supplies;
  final RestaurantRepository _restaurants;
  String _query = '';

  String get query => _query;

  List<SupplySection> get sections {
    final catalog = value;
    if (catalog == null) return const [];
    return _sections.group(catalog.supplies, catalog.categories, _query);
  }

  List<Supply> get expiring {
    final catalog = value;
    if (catalog == null || _query.isNotEmpty) return const [];
    return _sections.expiring(catalog.supplies);
  }

  @override
  Future<SuppliesCatalog> fetch() async {
    final (supplies, categories) = await (
      _supplies.all(),
      _restaurants.categories(),
    ).wait;
    return SuppliesCatalog(supplies: supplies, categories: categories);
  }

  void search(String query) {
    _query = query;
    notifyListeners();
  }
}
