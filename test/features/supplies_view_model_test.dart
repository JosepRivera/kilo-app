import 'package:flutter_test/flutter_test.dart';
import 'package:kilo_app/core/data_revision.dart';
import 'package:kilo_app/data/models/supply_detail.dart';
import 'package:kilo_app/features/supplies/supplies_view_model.dart';
import 'package:kilo_app/features/supplies/supply_detail_view_model.dart';

import '../support/fake_restaurant_repository.dart';
import '../support/fake_supply_repository.dart';
import '../support/fixtures.dart';

void main() {
  test('search filters sections and hides the expiring block', () async {
    final viewModel = SuppliesViewModel(
      supplies: FakeSupplyRepository([
        supply(id: 'a', name: 'Pollo entero', expiresInDays: 0),
        supply(id: 'b', name: 'Pechuga de pollo'),
        supply(id: 'c', name: 'Bistec'),
      ]),
      restaurants: FakeRestaurantRepository(),
    );
    await viewModel.load();
    expect(viewModel.sections.single.supplies, hasLength(3));
    expect(viewModel.expiring.single.id, 'a');

    viewModel.search('pollo');
    expect(viewModel.sections.single.supplies.map((s) => s.id), ['b', 'a']);
    expect(viewModel.expiring, isEmpty);
  });

  test('changing critical reloads the detail and bumps the data', () async {
    final repo = FakeSupplyRepository()
      ..detailResult = SupplyDetail(
        supply: supply(),
        recommendation: recommendation(),
        week: const [],
        recent: const [],
        lots: const [],
      );
    final revision = DataRevision();
    var bumps = 0;
    revision.addListener(() => bumps++);
    final viewModel = SupplyDetailViewModel(
      supplies: repo,
      revision: revision,
      supplyId: 'chicken-id',
    );
    await viewModel.load();
    expect(await viewModel.setCritical(false), isNull);
    expect(repo.criticalChanges, {'chicken-id': false});
    expect(bumps, 1);
    expect(viewModel.isSaving, isFalse);
  });
}
