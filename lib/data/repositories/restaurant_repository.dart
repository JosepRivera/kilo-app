import '../../core/api_client.dart';
import '../json.dart';
import '../models/registration.dart';
import '../models/restaurant.dart';
import '../models/supply_category.dart';

class RestaurantRepository {
  const RestaurantRepository(this._api);

  final ApiClient _api;

  Future<Registration> register({
    required String name,
    String? inviteCode,
  }) async {
    final json = await _api.post('/restaurants', {
      'name': name,
      'inviteCode': ?inviteCode,
    });
    return Registration.fromJson(json! as Json);
  }

  Future<Restaurant> current() async =>
      Restaurant.fromJson(await _api.get('/restaurant') as Json);

  Future<Restaurant> update({String? name, List<int>? closedWeekdays}) async {
    final json = await _api.patch('/restaurant', {
      'name': ?name,
      'closedWeekdays': ?closedWeekdays,
    });
    return Restaurant.fromJson(json! as Json);
  }

  Future<List<SupplyCategory>> categories() async =>
      decodeList(await _api.get('/categories'), SupplyCategory.fromJson);

  Future<SupplyCategory> updateCategory(
    String id, {
    int? purchaseIntervalDays,
    double? monthlySpend,
  }) async {
    final json = await _api.patch('/categories/$id', {
      'purchaseIntervalDays': ?purchaseIntervalDays,
      'monthlySpend': ?monthlySpend,
    });
    return SupplyCategory.fromJson(json! as Json);
  }
}
