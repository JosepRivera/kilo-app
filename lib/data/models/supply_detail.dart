import '../json.dart';
import 'forecast_day.dart';
import 'lot.dart';
import 'recent_day.dart';
import 'recommendation.dart';
import 'supply.dart';

class SupplyDetail {
  const SupplyDetail({
    required this.supply,
    required this.recommendation,
    required this.week,
    required this.recent,
    required this.lots,
  });

  factory SupplyDetail.fromJson(Json json) => SupplyDetail(
    supply: Supply.fromJson(json),
    recommendation: Recommendation.fromJson(json['recommendation']! as Json),
    week: decodeList(json['week'], ForecastDay.fromJson),
    recent: decodeList(json['recent'], RecentDay.fromJson),
    lots: decodeList(json['lots'], Lot.fromJson),
  );

  final Supply supply;
  final Recommendation recommendation;
  final List<ForecastDay> week;
  final List<RecentDay> recent;
  final List<Lot> lots;
}
