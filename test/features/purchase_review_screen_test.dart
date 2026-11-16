import 'package:flutter_test/flutter_test.dart';
import 'package:kilo_app/core/data_revision.dart';
import 'package:kilo_app/data/models/price_check.dart';
import 'package:kilo_app/data/models/resolution_kind.dart';
import 'package:kilo_app/data/models/voice_draft.dart';
import 'package:kilo_app/features/catalog/catalog_sheets.dart';
import 'package:kilo_app/features/purchase/purchase_review_screen.dart';
import 'package:kilo_app/features/purchase/purchase_review_view_model.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fake_record_repository.dart';
import '../support/fake_restaurant_repository.dart';
import '../support/fake_supply_repository.dart';
import '../support/fixtures.dart';
import '../support/test_app.dart';

void main() {
  final onion = supply(
    id: 'onion-id',
    name: 'Cebolla roja',
    shelfLifeDays: 14,
    priceCheck: const PriceCheck(usual: 2.5, low: 1.5, high: 3.5),
  );
  final tomato = supply(id: 'tomato-id', name: 'Tomate', shelfLifeDays: 5);

  late FakeSupplyRepository supplies;
  late FakeRecordRepository records;

  Future<void> pump(WidgetTester tester) async {
    supplies = FakeSupplyRepository([onion, tomato]);
    records = FakeRecordRepository();
    final viewModel = PurchaseReviewViewModel(
      supplies: supplies,
      restaurants: FakeRestaurantRepository(),
      records: records,
      revision: DataRevision(),
      voice: VoiceDraft(
        transcript: 'cebolla, tomate, limón y huacatay',
        items: [
          voiceItem(
            'cebolla',
            candidates: [candidate('Cebolla roja', supplyId: 'onion-id')],
            quantity: 2,
            cost: 8,
          ),
          voiceItem(
            'tomate',
            candidates: [candidate('Tomate', supplyId: 'tomato-id')],
            phrase: 'medio balde',
            cost: 12,
          ),
          voiceItem(
            'limón',
            kind: ResolutionKind.ambiguous,
            candidates: [candidate('Limón sutil'), candidate('Lima persa')],
            quantity: 1,
            cost: 4,
          ),
          voiceItem('huacatay', kind: ResolutionKind.unknown, quantity: 1),
        ],
      ),
      clock: () => DateTime.utc(2026, 11, 16, 15),
    );
    await viewModel.load();
    await pumpScreen(
      tester,
      PurchaseReviewScreen(
        viewModel: viewModel,
        catalog: CatalogSheets(supplies),
      ),
    );
  }

  testWidgets('every line kind asks what it needs', (tester) async {
    await pump(tester);
    expect(find.text('Cebolla roja'), findsOneWidget);
    expect(find.text('2 kg · S/8.00 · vence 30 nov'), findsOneWidget);
    expect(
      find.text(
        'Cebolla roja salió a S/4.00 por kg; normalmente la pagas a S/2.50. '
        '¿Es correcto?',
      ),
      findsOneWidget,
    );
    expect(
      find.text('¿Cuántos kg es «medio balde» de tomate?'),
      findsOneWidget,
    );
    expect(find.text('¿Cuál limón?'), findsOneWidget);
    expect(find.text('Huacatay no está en tu catálogo'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Total'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('S/20.00'), findsOneWidget);
  });

  testWidgets('resolving everything enables Confirmar', (tester) async {
    await pump(tester);
    final confirm = find.widgetWithText(TextButton, 'Confirmar');
    expect(tester.widget<TextButton>(confirm).onPressed, isNull);

    await tester.tap(find.text('Sí, es correcto'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, '6');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Listo'));
    await tester.pump();
    await tester.tap(find.text('Limón sutil'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Quitar'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Quitar'));
    await tester.pumpAndSettle();

    expect(tester.widget<TextButton>(confirm).onPressed, isNotNull);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(supplies.phrases.single, ('tomato-id', 'medio balde', 6.0));
    expect(records.purchases.single.map((l) => l.supplyId), [
      'onion-id',
      'tomato-id',
      'new-Limón sutil',
    ]);
  });
}
