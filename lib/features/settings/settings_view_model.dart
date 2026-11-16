import '../../core/data_revision.dart';
import '../../core/loadable.dart';
import '../../data/models/supply_category.dart';
import '../../data/repositories/record_repository.dart';
import '../../data/repositories/restaurant_repository.dart';
import 'settings_snapshot.dart';

class SettingsViewModel extends Loadable<SettingsSnapshot> {
  SettingsViewModel({
    required this._restaurants,
    required this._records,
    required this._revision,
  });

  static const maxPurchaseInterval = 60;

  final RestaurantRepository _restaurants;
  final RecordRepository _records;
  final DataRevision _revision;

  @override
  Future<SettingsSnapshot> fetch() async {
    final (restaurant, categories) = await (
      _restaurants.current(),
      _restaurants.categories(),
    ).wait;
    return SettingsSnapshot(restaurant: restaurant, categories: categories);
  }

  Future<String?> rename(String name) => _changeRestaurant(name: name.trim());

  Future<String?> toggleClosedWeekday(int weekday) {
    final closed = {...?value?.restaurant.closedWeekdays};
    if (!closed.remove(weekday)) closed.add(weekday);
    return _changeRestaurant(closedWeekdays: closed.toList()..sort());
  }

  Future<String?> setPurchaseInterval(SupplyCategory category, int days) =>
      _changeCategory(
        () => _restaurants.updateCategory(
          category.id,
          purchaseIntervalDays: days.clamp(1, maxPurchaseInterval),
        ),
      );

  Future<String?> setMonthlySpend(SupplyCategory category, double soles) =>
      _changeCategory(
        () => _restaurants.updateCategory(category.id, monthlySpend: soles),
      );

  Future<String?> markNoConsumption() => attempt(() async {
    await _records.markNoConsumption();
    _revision.bump();
  });

  Future<String?> _changeRestaurant({
    String? name,
    List<int>? closedWeekdays,
  }) => attempt(() async {
    final restaurant = await _restaurants.update(
      name: name,
      closedWeekdays: closedWeekdays,
    );
    final snapshot = value;
    if (snapshot != null) update(snapshot.withRestaurant(restaurant));
    _revision.bump();
  });

  Future<String?> _changeCategory(Future<SupplyCategory> Function() change) =>
      attempt(() async {
        final category = await change();
        final snapshot = value;
        if (snapshot != null) update(snapshot.withCategory(category));
        _revision.bump();
      });
}
