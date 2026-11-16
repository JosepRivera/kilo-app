import '../../core/api_client.dart';
import '../json.dart';
import '../models/purchase_line.dart';

class RecordRepository {
  const RecordRepository(this._api);

  final ApiClient _api;

  Future<void> closeStock(Map<String, double> remaining) =>
      _api.post('/stock-close', {'remaining': remaining});

  Future<void> markNoConsumption() => _api.post('/stock-close/none');

  Future<int> savePurchase(List<PurchaseLine> lines) async {
    final json = await _api.post('/purchases', {
      'lines': [for (final line in lines) line.toJson()],
    });
    return decodeInt((json! as Json)['lots']);
  }
}
