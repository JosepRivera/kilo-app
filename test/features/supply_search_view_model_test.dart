import 'package:flutter_test/flutter_test.dart';
import 'package:kilo_app/core/api_exception.dart';
import 'package:kilo_app/data/models/catalog_resolution.dart';
import 'package:kilo_app/data/models/resolution_kind.dart';
import 'package:kilo_app/features/catalog/candidate_resolver.dart';
import 'package:kilo_app/features/catalog/supply_search_view_model.dart';

import '../support/fake_supply_repository.dart';
import '../support/fixtures.dart';

void main() {
  test('lists candidates and offers creation when unknown', () async {
    final repo = FakeSupplyRepository()
      ..resolution = CatalogResolution(
        kind: ResolutionKind.ambiguous,
        candidates: [candidate('Limón sutil'), candidate('Lima persa')],
      );
    final viewModel = SupplySearchViewModel(repo);
    await viewModel.search('  ');
    expect(viewModel.term, isEmpty);

    await viewModel.search('limón');
    expect(viewModel.candidates, hasLength(2));
    expect(viewModel.hasNoMatch, isFalse);

    repo.resolution = const CatalogResolution(
      kind: ResolutionKind.unknown,
      candidates: [],
    );
    await viewModel.search('huacatay');
    expect(viewModel.hasNoMatch, isTrue);
    expect(viewModel.term, 'huacatay');

    repo.failure = const ApiException(0, 'Sin conexión');
    await viewModel.search('pollo');
    expect(viewModel.error, 'Sin conexión');
  });

  test('the resolver reuses owned supplies and creates catalog ones', () async {
    final owned = supply();
    final repo = FakeSupplyRepository([owned]);
    final candidateResolver = CandidateResolver(repo);
    expect(
      await candidateResolver.resolve(
        candidate('Pollo entero', supplyId: owned.id),
        [owned],
      ),
      same(owned),
    );
    expect(repo.created, isEmpty);
    final created = await candidateResolver.resolve(candidate('Ají limo'), [
      owned,
    ]);
    expect(created.name, 'Ají limo');
    expect(repo.created.single.name, 'Ají limo');
  });
}
