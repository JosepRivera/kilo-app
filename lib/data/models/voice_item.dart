import '../json.dart';
import 'catalog_resolution.dart';

class VoiceItem {
  const VoiceItem({
    required this.spoken,
    required this.resolution,
    required this.quantity,
    required this.phrase,
    required this.cost,
    required this.suggestedQuantity,
  });

  factory VoiceItem.fromJson(Json json) => VoiceItem(
    spoken: json['spoken']! as String,
    resolution: CatalogResolution.fromJson(json['resolution']! as Json),
    quantity: decodeOptionalDouble(json['quantity']),
    phrase: json['phrase'] as String?,
    cost: decodeOptionalDouble(json['cost']),
    suggestedQuantity: decodeOptionalDouble(json['suggestedQuantity']),
  );

  final String spoken;
  final CatalogResolution resolution;
  final double? quantity;
  final String? phrase;
  final double? cost;
  final double? suggestedQuantity;
}
