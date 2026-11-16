import '../../data/models/catalog_candidate.dart';
import '../../data/models/new_supply.dart';
import '../../data/models/supply.dart';
import '../../data/repositories/supply_repository.dart';

class CandidateResolver {
  const CandidateResolver(this._supplies);

  final SupplyRepository _supplies;

  Future<Supply> resolve(CatalogCandidate candidate, List<Supply> known) async {
    for (final supply in known) {
      if (supply.id == candidate.supplyId) return supply;
    }
    return _supplies.create(NewSupply(name: candidate.name));
  }

  Future<Supply> create(NewSupply supply) => _supplies.create(supply);
}
