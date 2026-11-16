import 'package:flutter_test/flutter_test.dart';
import 'package:kilo_app/core/api_exception.dart';
import 'package:kilo_app/core/data_revision.dart';
import 'package:kilo_app/data/models/today_overview.dart';
import 'package:kilo_app/features/today/today_view_model.dart';

import '../support/fake_insight_repository.dart';
import '../support/fake_supply_repository.dart';
import '../support/fixtures.dart';
import '../support/memory_stores.dart';

void main() {
  final chicken = supply();
  final rice = supply(id: 'rice', name: 'Arroz', icon: 'rice');
  final overview = TodayOverview(
    day: DateTime.utc(2026, 11, 16),
    alerts: const [],
    toBuy: [suggestion(chicken), suggestion(rice, bought: true)],
    covered: const [],
  );

  late FakeInsightRepository insights;
  late MemoryBoughtStore bought;
  late DataRevision revision;

  TodayViewModel build({List<String> supplies = const ['x']}) {
    insights = FakeInsightRepository(overview: overview);
    bought = MemoryBoughtStore();
    revision = DataRevision();
    return TodayViewModel(
      insights: insights,
      supplies: FakeSupplyRepository([
        for (final id in supplies) supply(id: id),
      ]),
      boughtStore: bought,
      refreshOn: revision,
    );
  }

  test('merges server bought with the local per-day check', () async {
    final viewModel = build();
    bought.days['2026-11-16'] = {chicken.id};
    await viewModel.load();
    expect(viewModel.isBought(viewModel.value!.toBuy.first), isTrue);
    expect(viewModel.isBought(viewModel.value!.toBuy.last), isTrue);
  });

  test('toggling persists under the business day', () async {
    final viewModel = build();
    await viewModel.load();
    final item = viewModel.value!.toBuy.first;
    await viewModel.toggleBought(item);
    expect(viewModel.isBought(item), isTrue);
    expect(bought.days['2026-11-16'], {chicken.id});
    await viewModel.toggleBought(item);
    expect(viewModel.isBought(item), isFalse);
    expect(bought.days['2026-11-16'], isEmpty);
  });

  test('server-bought rows cannot be unchecked', () async {
    final viewModel = build();
    await viewModel.load();
    await viewModel.toggleBought(viewModel.value!.toBuy.last);
    expect(bought.days, isEmpty);
  });

  test('asks for the first count only with no supplies at all', () async {
    final empty = TodayOverview(
      day: DateTime.utc(2026, 11, 16),
      alerts: const [],
      toBuy: const [],
      covered: const [],
    );
    final viewModel = build(supplies: const []);
    insights.overview = empty;
    await viewModel.load();
    expect(viewModel.needsFirstCount, isTrue);

    final withSupplies = build();
    insights.overview = empty;
    await withSupplies.load();
    expect(withSupplies.needsFirstCount, isFalse);
  });

  test('keeps one request in flight and reloads on data changes', () async {
    final viewModel = build();
    await Future.wait([viewModel.load(), viewModel.load()]);
    expect(insights.todayCalls, 1);
    revision.bump();
    await Future<void>.delayed(Duration.zero);
    expect(insights.todayCalls, 2);
    viewModel.dispose();
  });

  test('exposes the server error text', () async {
    final viewModel = build();
    insights.failure = const ApiException(0, 'Sin conexión');
    await viewModel.load();
    expect(viewModel.error, 'Sin conexión');
    expect(viewModel.value, isNull);
  });
}
