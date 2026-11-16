import '../json.dart';
import 'recommendation.dart';
import 'supply.dart';

class PurchaseSuggestion {
  const PurchaseSuggestion({
    required this.supply,
    required this.recommendation,
    required this.bought,
  });

  factory PurchaseSuggestion.fromJson(Json json) => PurchaseSuggestion(
    supply: Supply.fromJson(json['supply']! as Json),
    recommendation: Recommendation.fromJson(json['recommendation']! as Json),
    bought: json['bought']! as bool,
  );

  final Supply supply;
  final Recommendation recommendation;
  final bool bought;
}
