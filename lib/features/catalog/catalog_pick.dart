import '../../data/models/catalog_candidate.dart';
import '../../data/models/new_supply.dart';

class CatalogPick {
  const CatalogPick.candidate(CatalogCandidate this.candidate)
    : newSupply = null;

  const CatalogPick.create(NewSupply this.newSupply) : candidate = null;

  final CatalogCandidate? candidate;
  final NewSupply? newSupply;
}
