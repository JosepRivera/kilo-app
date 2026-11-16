import 'package:kilo_app/core/api_exception.dart';
import 'package:kilo_app/data/models/catalog_resolution.dart';
import 'package:kilo_app/data/models/new_supply.dart';
import 'package:kilo_app/data/models/resolution_kind.dart';
import 'package:kilo_app/data/models/supply.dart';
import 'package:kilo_app/data/models/supply_detail.dart';
import 'package:kilo_app/data/repositories/supply_repository.dart';

import 'fixtures.dart';

class FakeSupplyRepository implements SupplyRepository {
  FakeSupplyRepository([List<Supply>? supplies]) : supplies = [...?supplies];

  final List<Supply> supplies;
  final List<NewSupply> created = [];
  final Map<String, bool> criticalChanges = {};
  final List<(String, String, double)> phrases = [];
  CatalogResolution resolution = const CatalogResolution(
    kind: ResolutionKind.unknown,
    candidates: [],
  );
  SupplyDetail? detailResult;
  ApiException? failure;

  void _maybeFail() {
    final failure = this.failure;
    if (failure != null) throw failure;
  }

  @override
  Future<List<Supply>> all() async {
    _maybeFail();
    return [...supplies];
  }

  @override
  Future<SupplyDetail> detail(String id) async {
    _maybeFail();
    return detailResult!;
  }

  @override
  Future<Supply> create(NewSupply supply) async {
    _maybeFail();
    created.add(supply);
    final made = fixtureFor(supply);
    supplies.add(made);
    return made;
  }

  Supply fixtureFor(NewSupply request) => supply(
    id: 'new-${request.name}',
    name: request.name,
    unit: request.unit ?? 'kg',
    categoryId: request.categoryId ?? 'protein',
    icon: null,
    shelfLifeDays: request.shelfLifeDays ?? 7,
    expectedRemaining: 0,
  );

  @override
  Future<void> setCritical(String id, {required bool critical}) async {
    _maybeFail();
    criticalChanges[id] = critical;
  }

  @override
  Future<void> rememberPhrase(
    String id, {
    required String phrase,
    required double amount,
  }) async {
    _maybeFail();
    phrases.add((id, phrase, amount));
  }

  @override
  Future<CatalogResolution> resolve(String term) async {
    _maybeFail();
    return resolution;
  }
}
