import '../../data/models/catalog_candidate.dart';

class PendingItem {
  const PendingItem({
    required this.id,
    required this.spoken,
    required this.candidates,
    this.quantity,
  });

  final int id;
  final String spoken;
  final List<CatalogCandidate> candidates;
  final double? quantity;

  bool get isUnknown => candidates.isEmpty;
}
