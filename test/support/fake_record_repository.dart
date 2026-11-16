import 'package:kilo_app/core/api_exception.dart';
import 'package:kilo_app/data/models/purchase_line.dart';
import 'package:kilo_app/data/repositories/record_repository.dart';

class FakeRecordRepository implements RecordRepository {
  final List<Map<String, double>> closes = [];
  final List<List<PurchaseLine>> purchases = [];
  int noConsumptionCalls = 0;
  ApiException? failure;

  void _maybeFail() {
    final failure = this.failure;
    if (failure != null) throw failure;
  }

  @override
  Future<void> closeStock(Map<String, double> remaining) async {
    _maybeFail();
    closes.add(remaining);
  }

  @override
  Future<void> markNoConsumption() async {
    _maybeFail();
    noConsumptionCalls++;
  }

  @override
  Future<int> savePurchase(List<PurchaseLine> lines) async {
    _maybeFail();
    purchases.add(lines);
    return lines.length;
  }
}
