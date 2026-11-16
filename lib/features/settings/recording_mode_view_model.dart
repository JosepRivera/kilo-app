import '../../core/data_revision.dart';
import '../../core/loadable.dart';
import '../../data/models/supply.dart';
import '../../data/repositories/restaurant_repository.dart';
import '../../data/repositories/supply_repository.dart';
import '../supplies/supplies_catalog.dart';
import '../supplies/supply_section.dart';
import '../supplies/supply_sections.dart';

class RecordingModeViewModel extends Loadable<SuppliesCatalog> {
  RecordingModeViewModel({
    required this._supplies,
    required this._restaurants,
    required this._revision,
  });

  static const _sections = SupplySections();

  final SupplyRepository _supplies;
  final RestaurantRepository _restaurants;
  final DataRevision _revision;
  final Set<String> _saving = {};

  bool isSaving(Supply supply) => _saving.contains(supply.id);

  List<SupplySection> get sections {
    final catalog = value;
    if (catalog == null) return const [];
    return _sections.group(catalog.supplies, catalog.categories, '');
  }

  @override
  Future<SuppliesCatalog> fetch() async {
    final (supplies, categories) = await (
      _supplies.all(),
      _restaurants.categories(),
    ).wait;
    return SuppliesCatalog(supplies: supplies, categories: categories);
  }

  Future<String?> setCritical(Supply supply, bool critical) async {
    _saving.add(supply.id);
    notifyListeners();
    final error = await attempt(() async {
      await _supplies.setCritical(supply.id, critical: critical);
      update(await fetch());
      _revision.bump();
    });
    _saving.remove(supply.id);
    notifyListeners();
    return error;
  }
}
