import 'package:kilo_app/core/api_exception.dart';
import 'package:kilo_app/data/models/registration.dart';
import 'package:kilo_app/data/models/restaurant.dart';
import 'package:kilo_app/data/models/supply_category.dart';
import 'package:kilo_app/data/repositories/restaurant_repository.dart';

import 'fixtures.dart';

class FakeRestaurantRepository implements RestaurantRepository {
  Restaurant restaurant = const Restaurant(
    id: 'r1',
    name: 'Doña Rosa',
    closedWeekdays: [7],
  );
  List<SupplyCategory> categoryList = const [category];
  final List<(String, String?)> registrations = [];
  final List<Map<String, Object?>> categoryChanges = [];
  ApiException? failure;

  void _maybeFail() {
    final failure = this.failure;
    if (failure != null) throw failure;
  }

  @override
  Future<Registration> register({
    required String name,
    String? inviteCode,
  }) async {
    _maybeFail();
    registrations.add((name, inviteCode));
    return Registration(token: 'token-1', restaurant: restaurant);
  }

  @override
  Future<Restaurant> current() async {
    _maybeFail();
    return restaurant;
  }

  @override
  Future<Restaurant> update({String? name, List<int>? closedWeekdays}) async {
    _maybeFail();
    restaurant = Restaurant(
      id: restaurant.id,
      name: name ?? restaurant.name,
      closedWeekdays: closedWeekdays ?? restaurant.closedWeekdays,
    );
    return restaurant;
  }

  @override
  Future<List<SupplyCategory>> categories() async {
    _maybeFail();
    return categoryList;
  }

  @override
  Future<SupplyCategory> updateCategory(
    String id, {
    int? purchaseIntervalDays,
    double? monthlySpend,
  }) async {
    _maybeFail();
    categoryChanges.add({
      'id': id,
      'purchaseIntervalDays': purchaseIntervalDays,
      'monthlySpend': monthlySpend,
    });
    final current = categoryList.firstWhere((c) => c.id == id);
    return SupplyCategory(
      id: id,
      name: current.name,
      purchaseIntervalDays:
          purchaseIntervalDays ?? current.purchaseIntervalDays,
      monthlySpend: monthlySpend ?? current.monthlySpend,
      critical: current.critical,
    );
  }
}
