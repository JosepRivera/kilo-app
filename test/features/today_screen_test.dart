import 'package:flutter_test/flutter_test.dart';
import 'package:kilo_app/data/models/expiring_lot.dart';
import 'package:kilo_app/data/models/expiry_alert.dart';
import 'package:kilo_app/data/models/today_overview.dart';
import 'package:kilo_app/features/today/today_screen.dart';
import 'package:kilo_app/features/today/today_view_model.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fake_insight_repository.dart';
import '../support/fake_supply_repository.dart';
import '../support/fixtures.dart';
import '../support/memory_stores.dart';
import '../support/test_app.dart';

void main() {
  final chicken = supply();
  final fish = supply(id: 'fish-id', name: 'Pescado', icon: 'fish');
  final rice = supply(id: 'rice-id', name: 'Arroz', icon: 'rice');
  final today = DateTime.utc(2026, 11, 16);

  TodayOverview overview({List<ExpiryAlert> alerts = const []}) =>
      TodayOverview(
        day: today,
        alerts: alerts,
        toBuy: [suggestion(chicken)],
        covered: [rice],
      );

  ExpiryAlert alert(String id, String name, int daysLeft) => ExpiryAlert(
    supply: supply(id: id, name: name),
    daysLeft: daysLeft,
    remaining: 6,
    lots: [ExpiringLot(purchasedOn: today, remaining: 6, daysLeft: daysLeft)],
  );

  Future<(TodayViewModel, List<String>)> pump(
    WidgetTester tester,
    TodayOverview data, {
    List<String> supplies = const ['x'],
  }) async {
    final explained = <String>[];
    final viewModel = TodayViewModel(
      insights: FakeInsightRepository(overview: data),
      supplies: FakeSupplyRepository([
        for (final id in supplies) supply(id: id),
      ]),
      boughtStore: MemoryBoughtStore(),
    );
    await viewModel.load();
    await pumpScreen(
      tester,
      TodayScreen(
        viewModel: viewModel,
        onOpenSettings: (_) {},
        onExplain: (_, id) => explained.add(id),
        onStartFirstCount: (_) => explained.add('first-count'),
      ),
    );
    return (viewModel, explained);
  }

  testWidgets('shows the date, purchase list and covered grid', (tester) async {
    await pump(tester, overview());
    expect(find.text('Compra de hoy'), findsOneWidget);
    expect(find.text('Lunes 16 de noviembre'), findsOneWidget);
    expect(find.text('Hasta tu próxima compra'), findsOneWidget);
    expect(find.text('27 kg'), findsOneWidget);
    expect(find.text('Kilo aún aprende'), findsOneWidget);
    expect(find.text('Ya alcanza'), findsOneWidget);
    expect(find.text('Arroz'), findsOneWidget);
  });

  testWidgets('the most urgent alert leads and links to the rest', (
    tester,
  ) async {
    await pump(
      tester,
      overview(
        alerts: [alert('fish-id', 'Pescado', 0), alert('x', 'Leche', 1)],
      ),
    );
    expect(find.text('El lote de hoy vence hoy'), findsOneWidget);
    expect(find.textContaining('Pescado · quedan 6 kg'), findsOneWidget);
    await tester.tap(find.text('Ver todo lo que vence (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Por vencer'), findsWidgets);
    expect(find.textContaining('Leche'), findsOneWidget);
    expect(fish.name, 'Pescado');
  });

  testWidgets('toggling bought strikes the row and tapping explains', (
    tester,
  ) async {
    final (_, explained) = await pump(tester, overview());
    await tester.tap(find.byTooltip('Marcar como comprado'));
    await tester.pumpAndSettle();
    expect(find.text('Comprado'), findsWidgets);
    await tester.tap(find.text('Pollo entero'));
    expect(explained, ['chicken-id']);
  });

  testWidgets('nudges the first count when nothing exists', (tester) async {
    final (_, started) = await pump(
      tester,
      TodayOverview(
        day: today,
        alerts: const [],
        toBuy: const [],
        covered: const [],
      ),
      supplies: const [],
    );
    await tester.tap(find.text('Hacer el primer conteo'));
    expect(started, ['first-count']);
  });

  testWidgets('empty list says there is nothing to buy', (tester) async {
    await pump(
      tester,
      TodayOverview(
        day: today,
        alerts: const [],
        toBuy: const [],
        covered: [rice],
      ),
    );
    expect(find.text('Ya tienes todo lo de hoy'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
