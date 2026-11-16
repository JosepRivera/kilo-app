import '../../core/api_client.dart';
import '../json.dart';
import '../models/catalog_resolution.dart';
import '../models/new_supply.dart';
import '../models/supply.dart';
import '../models/supply_detail.dart';

class SupplyRepository {
  const SupplyRepository(this._api);

  final ApiClient _api;

  Future<List<Supply>> all() async =>
      decodeList(await _api.get('/supplies'), Supply.fromJson);

  Future<SupplyDetail> detail(String id) async =>
      SupplyDetail.fromJson(await _api.get('/supplies/$id') as Json);

  Future<Supply> create(NewSupply supply) async =>
      Supply.fromJson(await _api.post('/supplies', supply.toJson()) as Json);

  Future<void> setCritical(String id, {required bool critical}) =>
      _api.patch('/supplies/$id', {'critical': critical});

  Future<void> rememberPhrase(
    String id, {
    required String phrase,
    required double amount,
  }) => _api.put('/supplies/$id/phrases', {'phrase': phrase, 'amount': amount});

  Future<CatalogResolution> resolve(String term) async {
    final json = await _api.get('/catalog/resolve', query: {'term': term});
    return CatalogResolution.fromJson(json! as Json);
  }
}
