import '../../data/models/catalog_candidate.dart';
import '../../data/models/supply.dart';

class PurchaseLineDraft {
  const PurchaseLineDraft({
    required this.id,
    required this.spoken,
    this.supply,
    this.candidates = const [],
    this.quantity,
    this.cost,
    this.expiresOn,
    this.phrase,
    this.phraseAnswered = false,
    this.priceConfirmed = false,
  });

  final int id;
  final String spoken;
  final Supply? supply;
  final List<CatalogCandidate> candidates;
  final double? quantity;
  final double? cost;
  final DateTime? expiresOn;
  final String? phrase;
  final bool phraseAnswered;
  final bool priceConfirmed;

  bool get isUnknown => supply == null && candidates.isEmpty;

  bool get asksMeasure => supply != null && phrase != null && !phraseAnswered;

  String? get phraseToRemember => phraseAnswered ? phrase : null;

  PurchaseLineDraft resolvedAs(Supply supply, DateTime expiresOn) =>
      _copy(supply: supply, candidates: const [], expiresOn: expiresOn);

  PurchaseLineDraft withQuantity(double? quantity) =>
      _copy(quantity: quantity, quantityChanged: true, priceConfirmed: false);

  PurchaseLineDraft withCost(double? cost) =>
      _copy(cost: cost, costChanged: true, priceConfirmed: false);

  PurchaseLineDraft withExpiry(DateTime expiresOn) =>
      _copy(expiresOn: expiresOn);

  PurchaseLineDraft withMeasure(double quantity) => _copy(
    quantity: quantity,
    quantityChanged: true,
    phraseAnswered: true,
    priceConfirmed: false,
  );

  PurchaseLineDraft withPriceConfirmed() => _copy(priceConfirmed: true);

  PurchaseLineDraft _copy({
    Supply? supply,
    List<CatalogCandidate>? candidates,
    double? quantity,
    bool quantityChanged = false,
    double? cost,
    bool costChanged = false,
    DateTime? expiresOn,
    bool? phraseAnswered,
    bool? priceConfirmed,
  }) => PurchaseLineDraft(
    id: id,
    spoken: spoken,
    supply: supply ?? this.supply,
    candidates: candidates ?? this.candidates,
    quantity: quantityChanged ? quantity : this.quantity,
    cost: costChanged ? cost : this.cost,
    expiresOn: expiresOn ?? this.expiresOn,
    phrase: phrase,
    phraseAnswered: phraseAnswered ?? this.phraseAnswered,
    priceConfirmed: priceConfirmed ?? this.priceConfirmed,
  );
}
