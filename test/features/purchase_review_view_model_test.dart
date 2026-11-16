import 'package:flutter_test/flutter_test.dart';
import 'package:kilo_app/core/data_revision.dart';
import 'package:kilo_app/data/models/new_supply.dart';
import 'package:kilo_app/data/models/price_check.dart';
import 'package:kilo_app/data/models/resolution_kind.dart';
import 'package:kilo_app/data/models/voice_draft.dart';
import 'package:kilo_app/features/purchase/line_problem.dart';
import 'package:kilo_app/features/purchase/purchase_review_view_model.dart';

import '../support/fake_record_repository.dart';
import '../support/fake_restaurant_repository.dart';
import '../support/fake_supply_repository.dart';
import '../support/fixtures.dart';

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

  PurchaseReviewViewModel build({VoiceDraft? voice}) {
    supplies = FakeSupplyRepository([onion, tomato]);
    records = FakeRecordRepository();
    return PurchaseReviewViewModel(
      supplies: supplies,
      restaurants: FakeRestaurantRepository(),
      records: records,
      revision: DataRevision(),
      voice: voice,
      clock: () => DateTime.utc(2026, 11, 16, 15),
    );
  }

  final dictated = VoiceDraft(
    transcript: 'dos kilos de cebolla a ocho soles, medio balde de tomate',
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
        quantity: 0.5,
        cost: 3,
      ),
      voiceItem('huacatay', kind: ResolutionKind.unknown, quantity: 1, cost: 2),
    ],
  );

  test('builds lines from the dictation with default expiry', () async {
    final viewModel = build(voice: dictated);
    await viewModel.load();
    final lines = viewModel.lines;
    expect(lines, hasLength(4));
    expect(lines[0].supply!.id, 'onion-id');
    expect(lines[0].expiresOn, DateTime.utc(2026, 11, 30));
    expect(lines[1].asksMeasure, isTrue);
    expect(lines[2].supply, isNull);
    expect(lines[3].isUnknown, isTrue);
    expect(viewModel.total, 20);
    expect(viewModel.canSave, isFalse);
  });

  test('the price flag must be confirmed or corrected', () async {
    final viewModel = build(voice: dictated);
    await viewModel.load();
    final line = viewModel.lines.first;
    expect(viewModel.priceFlagOf(line)!.unitPrice, 4);
    expect(viewModel.problemOf(line), LineProblem.price);
    viewModel.confirmPrice(line.id);
    expect(viewModel.problemOf(viewModel.lines.first), isNull);
    viewModel.setCost(line.id, 5);
    expect(viewModel.priceFlagOf(viewModel.lines.first), isNull);
  });

  test('resolves ambiguous and unknown lines through the API', () async {
    final viewModel = build(voice: dictated);
    await viewModel.load();
    final lemon = viewModel.lines[2];
    await viewModel.pickCandidate(lemon.id, lemon.candidates.first);
    expect(supplies.created.single.name, 'Limón sutil');
    expect(viewModel.lines[2].supply!.name, 'Limón sutil');
    expect(viewModel.lines[2].quantity, 0.5);

    final herb = viewModel.lines[3];
    await viewModel.createSupply(
      herb.id,
      const NewSupply(
        name: 'Huacatay',
        unit: 'atados',
        categoryId: 'protein',
        shelfLifeDays: 4,
      ),
    );
    expect(viewModel.lines[3].supply!.unit, 'atados');
    expect(viewModel.lines[3].expiresOn, DateTime.utc(2026, 11, 20));
  });

  test('saving remembers the answered measure and posts lots', () async {
    final viewModel = build(voice: dictated);
    await viewModel.load();
    final lines = viewModel.lines;
    viewModel
      ..confirmPrice(lines[0].id)
      ..answerMeasure(lines[1].id, 6)
      ..remove(lines[2].id)
      ..remove(lines[3].id);
    expect(viewModel.canSave, isTrue);
    expect(await viewModel.save(), isNull);
    expect(supplies.phrases.single, ('tomato-id', 'medio balde', 6.0));
    final saved = records.purchases.single;
    expect(saved.map((l) => l.supplyId), ['onion-id', 'tomato-id']);
    expect(saved.last.quantity, 6);
    expect(saved.last.cost, 12);
    expect(saved.last.expiresOn, DateTime.utc(2026, 11, 21));
  });

  test('manual entry starts empty and adds searched supplies', () async {
    final viewModel = build();
    await viewModel.load();
    expect(viewModel.lines, isEmpty);
    expect(viewModel.hasUnsavedEdits, isFalse);
    await viewModel.addCandidate(candidate('Tomate', supplyId: 'tomato-id'));
    final line = viewModel.lines.single;
    expect(viewModel.problemOf(line), LineProblem.quantity);
    viewModel
      ..setQuantity(line.id, 3)
      ..setCost(line.id, 9)
      ..setExpiry(line.id, DateTime.utc(2026, 11, 18));
    expect(viewModel.canSave, isTrue);
    expect(viewModel.lines.single.expiresOn, DateTime.utc(2026, 11, 18));
    expect(supplies.created, isEmpty);
  });
}
