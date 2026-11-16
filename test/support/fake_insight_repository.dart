import 'package:kilo_app/core/api_exception.dart';
import 'package:kilo_app/data/models/savings.dart';
import 'package:kilo_app/data/models/today_overview.dart';
import 'package:kilo_app/data/repositories/insight_repository.dart';

class FakeInsightRepository implements InsightRepository {
  FakeInsightRepository({this.overview, this.savingsResult});

  TodayOverview? overview;
  Savings? savingsResult;
  ApiException? failure;
  int todayCalls = 0;

  @override
  Future<TodayOverview> today() async {
    todayCalls++;
    final failure = this.failure;
    if (failure != null) throw failure;
    return overview!;
  }

  @override
  Future<Savings> savings() async {
    final failure = this.failure;
    if (failure != null) throw failure;
    return savingsResult!;
  }
}
