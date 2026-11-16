import 'package:kilo_app/data/models/catalog_candidate.dart';
import 'package:kilo_app/data/models/catalog_resolution.dart';
import 'package:kilo_app/data/models/close_check.dart';
import 'package:kilo_app/data/models/price_check.dart';
import 'package:kilo_app/data/models/purchase_suggestion.dart';
import 'package:kilo_app/data/models/recommendation.dart';
import 'package:kilo_app/data/models/resolution_kind.dart';
import 'package:kilo_app/data/models/supply.dart';
import 'package:kilo_app/data/models/supply_category.dart';
import 'package:kilo_app/data/models/voice_item.dart';

Supply supply({
  String id = 'chicken-id',
  String name = 'Pollo entero',
  String unit = 'kg',
  String categoryId = 'protein',
  String? icon = 'chicken',
  bool critical = true,
  int shelfLifeDays = 3,
  double referencePrice = 9.5,
  double stock = 12,
  int realDays = 9,
  bool learning = true,
  int? expiresInDays,
  bool dueForClose = true,
  double expectedRemaining = 8,
  CloseCheck? closeCheck,
  PriceCheck? priceCheck,
}) => Supply(
  id: id,
  name: name,
  unit: unit,
  categoryId: categoryId,
  icon: icon,
  critical: critical,
  shelfLifeDays: shelfLifeDays,
  referencePrice: referencePrice,
  phrases: const {},
  stock: stock,
  realDays: realDays,
  learning: learning,
  expiresInDays: expiresInDays,
  dueForClose: dueForClose,
  expectedRemaining: expectedRemaining,
  closeCheck: closeCheck,
  priceCheck: priceCheck,
);

const category = SupplyCategory(
  id: 'protein',
  name: 'Proteínas',
  purchaseIntervalDays: 3,
  monthlySpend: 1200,
  critical: true,
);

Recommendation recommendation({double toBuy = 27, double onHand = 12}) =>
    Recommendation(
      toBuy: toBuy,
      onHand: onHand,
      demand: 30,
      buffer: 8.9,
      horizonDays: 3,
      typicalError: 4,
    );

PurchaseSuggestion suggestion(Supply supply, {bool bought = false}) =>
    PurchaseSuggestion(
      supply: supply,
      recommendation: recommendation(),
      bought: bought,
    );

CatalogCandidate candidate(
  String name, {
  String? supplyId,
  String unit = 'kg',
}) => CatalogCandidate(
  supplyId: supplyId,
  name: name,
  unit: unit,
  category: null,
);

VoiceItem voiceItem(
  String spoken, {
  ResolutionKind kind = ResolutionKind.exact,
  List<CatalogCandidate> candidates = const [],
  double? quantity,
  String? phrase,
  double? cost,
  double? suggestedQuantity,
}) => VoiceItem(
  spoken: spoken,
  resolution: CatalogResolution(kind: kind, candidates: candidates),
  quantity: quantity,
  phrase: phrase,
  cost: cost,
  suggestedQuantity: suggestedQuantity,
);
