import 'package:flutter_test/flutter_test.dart';
import 'package:kilo_app/core/api_exception.dart';
import 'package:kilo_app/core/data_revision.dart';
import 'package:kilo_app/data/models/close_check.dart';
import 'package:kilo_app/data/models/close_draft.dart';
import 'package:kilo_app/data/models/resolution_kind.dart';
import 'package:kilo_app/data/models/voice_draft.dart';
import 'package:kilo_app/features/stock_close/stock_close_view_model.dart';

import '../support/fake_record_repository.dart';
import '../support/fake_restaurant_repository.dart';
import '../support/fake_supply_repository.dart';
import '../support/fixtures.dart';
import '../support/memory_stores.dart';

void main() {
  final chicken = supply(
    closeCheck: const CloseCheck(
      base: 12,
      gapDays: 1,
      usual: 4,
      reviewBelow: 1,
    ),
  );
  final egg = supply(
    id: 'egg-id',
    name: 'Huevos',
    unit: 'unidades',
    expectedRemaining: 30,
  );
  final salt = supply(id: 'salt-id', name: 'Sal', dueForClose: false);

  late FakeSupplyRepository supplies;
  late FakeRecordRepository records;
  late MemoryCloseDraftStore drafts;

  StockCloseViewModel build({VoiceDraft? voice}) {
    supplies = FakeSupplyRepository([chicken, egg, salt]);
    records = FakeRecordRepository();
    return StockCloseViewModel(
      supplies: supplies,
      restaurants: FakeRestaurantRepository(),
      records: records,
      drafts: drafts,
      revision: DataRevision(),
      voice: voice,
      clock: () => DateTime.utc(2026, 11, 17, 2),
    );
  }

  setUp(() => drafts = MemoryCloseDraftStore());

  test('asks for due supplies prefilled with the expected remaining', () async {
    final viewModel = build();
    await viewModel.load();
    expect(viewModel.entries.map((e) => e.supply.id), ['chicken-id', 'egg-id']);
    expect(viewModel.entries.map((e) => e.remaining), [8, 30]);
    expect(viewModel.canSave, isTrue);
  });

  test('voice values win and suggestions wait for the user', () async {
    final viewModel = build(
      voice: VoiceDraft(
        transcript: 'quedan trece huevos',
        items: [
          voiceItem(
            'huevos',
            candidates: [candidate('Huevos', supplyId: 'egg-id')],
            quantity: 13,
            suggestedQuantity: 3,
          ),
          voiceItem(
            'sal',
            candidates: [candidate('Sal', supplyId: 'salt-id')],
            quantity: 2,
          ),
        ],
      ),
    );
    await viewModel.load();
    final eggs = viewModel.entries.firstWhere((e) => e.supply.id == 'egg-id');
    expect(eggs.remaining, 13);
    expect(eggs.suggested, 3);
    expect(viewModel.entries.map((e) => e.supply.id), contains('salt-id'));
    expect(viewModel.canSave, isFalse);

    viewModel.acceptSuggestion('egg-id');
    expect(
      viewModel.entries.firstWhere((e) => e.supply.id == 'egg-id').remaining,
      3,
    );
    expect(viewModel.canSave, isTrue);
  });

  test('keeping the heard value also clears the suggestion', () async {
    final viewModel = build(
      voice: VoiceDraft(
        transcript: '',
        items: [
          voiceItem(
            'huevos',
            candidates: [candidate('Huevos', supplyId: 'egg-id')],
            quantity: 13,
            suggestedQuantity: 3,
          ),
        ],
      ),
    );
    await viewModel.load();
    viewModel.keepHeard('egg-id');
    expect(viewModel.entries.last.remaining, 13);
    expect(viewModel.canSave, isTrue);
  });

  test('a low remaining needs review until confirmed or corrected', () async {
    final viewModel = build();
    await viewModel.load();
    viewModel.setRemaining('chicken-id', 0);
    final entry = viewModel.entries.first;
    expect(viewModel.flagOf(entry)!.consumed, 12);
    expect(viewModel.needsReview(entry), isTrue);
    expect(viewModel.canSave, isFalse);

    viewModel.confirmFlag('chicken-id');
    expect(viewModel.canSave, isTrue);
    viewModel.setRemaining('chicken-id', 0.5);
    expect(viewModel.canSave, isFalse);
    viewModel.setRemaining('chicken-id', 5);
    expect(viewModel.canSave, isTrue);
  });

  test('an empty value blocks saving', () async {
    final viewModel = build();
    await viewModel.load();
    viewModel.setRemaining('egg-id', null);
    expect(viewModel.canSave, isFalse);
  });

  test('every edit is kept as a draft and resumed on reopening', () async {
    final first = build();
    await first.load();
    first.setRemaining('egg-id', 12);
    expect(drafts.draft!.day, '2026-11-16');
    expect(drafts.draft!.remaining['egg-id'], 12);

    final reopened = build();
    await reopened.load();
    expect(reopened.resumedFromDraft, isTrue);
    expect(reopened.entries.last.remaining, 12);
    expect(reopened.hasUnsavedEdits, isTrue);
  });

  test("yesterday's draft is ignored and restart clears it", () async {
    drafts.draft = const CloseDraft(
      day: '2026-11-15',
      remaining: {'egg-id': 1},
      transcript: null,
    );
    final viewModel = build();
    await viewModel.load();
    expect(viewModel.resumedFromDraft, isFalse);

    viewModel.setRemaining('egg-id', 5);
    await viewModel.restart();
    expect(drafts.draft, isNull);
    expect(viewModel.entries.last.remaining, 30);
  });

  test('saving posts the counts and clears the draft', () async {
    final viewModel = build();
    await viewModel.load();
    viewModel.setRemaining('egg-id', 24);
    expect(await viewModel.save(), isNull);
    expect(records.closes.single, {'chicken-id': 8.0, 'egg-id': 24.0});
    expect(drafts.draft, isNull);
    expect(viewModel.hasUnsavedEdits, isFalse);
  });

  test('a failed save keeps the draft', () async {
    final viewModel = build();
    await viewModel.load();
    viewModel.setRemaining('egg-id', 24);
    records.failure = const ApiException(0, 'Sin conexión');
    expect(await viewModel.save(), 'Sin conexión');
    expect(drafts.draft, isNotNull);
  });

  test('ambiguous and unknown items must be resolved first', () async {
    final viewModel = build(
      voice: VoiceDraft(
        transcript: '',
        items: [
          voiceItem(
            'limón',
            kind: ResolutionKind.ambiguous,
            candidates: [candidate('Limón sutil'), candidate('Lima persa')],
            quantity: 2,
          ),
          voiceItem('huacatay', kind: ResolutionKind.unknown, quantity: 1),
        ],
      ),
    );
    await viewModel.load();
    expect(viewModel.pending, hasLength(2));
    expect(viewModel.canSave, isFalse);

    await viewModel.pickCandidate(
      viewModel.pending.first,
      viewModel.pending.first.candidates.first,
    );
    expect(supplies.created.single.name, 'Limón sutil');
    expect(viewModel.entries.last.remaining, 2);

    viewModel.removePending(viewModel.pending.single);
    expect(viewModel.pending, isEmpty);
    expect(viewModel.canSave, isTrue);
  });

  test('the first count starts empty and grows from the catalog', () async {
    final viewModel = StockCloseViewModel(
      supplies: FakeSupplyRepository(),
      restaurants: FakeRestaurantRepository(),
      records: FakeRecordRepository(),
      drafts: drafts,
      revision: DataRevision(),
      clock: () => DateTime.utc(2026, 11, 17, 2),
    );
    await viewModel.load();
    expect(viewModel.entries, isEmpty);
    expect(viewModel.canSave, isFalse);
    await viewModel.addCandidate(candidate('Pollo entero'));
    viewModel.setRemaining('new-Pollo entero', 10);
    expect(viewModel.canSave, isTrue);
  });
}
