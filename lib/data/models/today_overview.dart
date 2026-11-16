import '../../core/day.dart';
import '../json.dart';
import 'expiry_alert.dart';
import 'purchase_suggestion.dart';
import 'supply.dart';

class TodayOverview {
  const TodayOverview({
    required this.day,
    required this.alerts,
    required this.toBuy,
    required this.covered,
  });

  factory TodayOverview.fromJson(Json json) => TodayOverview(
    day: parseDay(json['day']! as String),
    alerts: decodeList(json['alerts'], ExpiryAlert.fromJson),
    toBuy: decodeList(json['toBuy'], PurchaseSuggestion.fromJson),
    covered: decodeList(json['covered'], Supply.fromJson),
  );

  final DateTime day;
  final List<ExpiryAlert> alerts;
  final List<PurchaseSuggestion> toBuy;
  final List<Supply> covered;

  bool get isEmpty => alerts.isEmpty && toBuy.isEmpty && covered.isEmpty;
}
