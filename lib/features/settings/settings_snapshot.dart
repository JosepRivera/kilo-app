import '../../data/models/restaurant.dart';
import '../../data/models/supply_category.dart';

class SettingsSnapshot {
  const SettingsSnapshot({required this.restaurant, required this.categories});

  final Restaurant restaurant;
  final List<SupplyCategory> categories;

  SettingsSnapshot withRestaurant(Restaurant restaurant) =>
      SettingsSnapshot(restaurant: restaurant, categories: categories);

  SettingsSnapshot withCategory(SupplyCategory updated) => SettingsSnapshot(
    restaurant: restaurant,
    categories: [
      for (final category in categories)
        category.id == updated.id ? updated : category,
    ],
  );
}
