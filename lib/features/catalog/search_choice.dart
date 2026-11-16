import '../../data/models/catalog_candidate.dart';

class SearchChoice {
  const SearchChoice.candidate(CatalogCandidate this.candidate)
    : newName = null;

  const SearchChoice.create(String this.newName) : candidate = null;

  final CatalogCandidate? candidate;
  final String? newName;
}
