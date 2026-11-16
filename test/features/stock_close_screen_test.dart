import 'package:flutter_test/flutter_test.dart';
import 'package:kilo_app/core/data_revision.dart';
import 'package:kilo_app/data/models/close_check.dart';
import 'package:kilo_app/data/models/voice_draft.dart';
import 'package:kilo_app/features/catalog/catalog_sheets.dart';
import 'package:kilo_app/features/stock_close/stock_close_screen.dart';
import 'package:kilo_app/features/stock_close/stock_close_view_model.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fake_record_repository.dart';
import '../support/fake_restaurant_repository.dart';
import '../support/fake_supply_repository.dart';
import '../support/fixtures.dart';
import '../support/memory_stores.dart';
import '../support/test_app.dart';

void main() {
  final chicken = supply(
    closeCheck: const CloseCheck(
      base: 12,
      gapDays: 1,
      usual: 4,
      reviewBelow: 1,
    ),
  );
  final egg = supply(id: 'egg-id', name: 'Huevos', unit: 'unidades');

  late FakeRecordRepository records;

  Future<StockCloseViewModel> pump(
    WidgetTester tester,
    VoiceDraft voice,
  ) async {
    final supplies = FakeSupplyRepository([chicken, egg]);
    records = FakeRecordRepository();
    final viewModel = StockCloseViewModel(
      supplies: supplies,
      restaurants: FakeRestaurantRepository(),
      records: records,
      drafts: MemoryCloseDraftStore(),
      revision: DataRevision(),
      voice: voice,
      clock: () => DateTime.utc(2026, 11, 17, 2),
    );
    await viewModel.load();
    await pumpScreen(
      tester,
      StockCloseScreen(viewModel: viewModel, catalog: CatalogSheets(supplies)),
    );
    return viewModel;
  }

  testWidgets('flags, suggests and saves only once resolved', (tester) async {
    await pump(
      tester,
      VoiceDraft(
        transcript: 'no queda pollo y trece huevos',
        items: [
          voiceItem(
            'pollo',
            candidates: [candidate('Pollo entero', supplyId: 'chicken-id')],
            quantity: 0,
          ),
          voiceItem(
            'huevos',
            candidates: [candidate('Huevos', supplyId: 'egg-id')],
            quantity: 13,
            suggestedQuantity: 3,
          ),
        ],
      ),
    );
    expect(find.text('«no queda pollo y trece huevos»'), findsOneWidget);
    expect(
      find.text(
        'Según lo que dictaste, hoy se usaron 12 kg de pollo entero; '
        'normalmente son unos 4 kg. ¿Es correcto?',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Escuché «13 unidades», pero según tu historial quedarían unos '
        '3 unidades. ¿Quisiste decir 3 unidades?',
      ),
      findsOneWidget,
    );
    final save = find.widgetWithText(TextButton, 'Guardar');
    expect(tester.widget<TextButton>(save).onPressed, isNull);

    await tester.tap(find.text('Sí, es correcto'));
    await tester.pump();
    await tester.tap(find.text('Sí, 3 unidades'));
    await tester.pump();
    expect(tester.widget<TextButton>(save).onPressed, isNotNull);

    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(records.closes.single, {'chicken-id': 0.0, 'egg-id': 3.0});
  });

  testWidgets('typing a value updates the count', (tester) async {
    final viewModel = await pump(
      tester,
      const VoiceDraft(transcript: '', items: []),
    );
    await tester.enterText(find.byType(TextField).last, '2,5');
    expect(viewModel.entries.last.remaining, 2.5);
    expect(find.text('Lo que queda'), findsOneWidget);
    expect(find.text('Hoy no hubo consumo'), findsOneWidget);
  });
}
