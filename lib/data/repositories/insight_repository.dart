import '../../core/api_client.dart';
import '../json.dart';
import '../models/savings.dart';
import '../models/today_overview.dart';

class InsightRepository {
  const InsightRepository(this._api);

  final ApiClient _api;

  Future<TodayOverview> today() async =>
      TodayOverview.fromJson(await _api.get('/today') as Json);

  Future<Savings> savings() async =>
      Savings.fromJson(await _api.get('/savings') as Json);
}
