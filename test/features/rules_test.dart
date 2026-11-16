import 'package:flutter_test/flutter_test.dart';
import 'package:kilo_app/data/models/close_check.dart';
import 'package:kilo_app/data/models/forecast_day.dart';
import 'package:kilo_app/data/models/price_check.dart';
import 'package:kilo_app/data/models/supply_category.dart';
import 'package:kilo_app/data/models/voice_kind.dart';
import 'package:kilo_app/features/purchase/line_problem.dart';
import 'package:kilo_app/features/purchase/purchase_line_draft.dart';
import 'package:kilo_app/features/purchase/purchase_line_rules.dart';
import 'package:kilo_app/features/stock_close/close_review_rules.dart';
import 'package:kilo_app/features/supplies/peak_days.dart';
import 'package:kilo_app/features/supplies/supply_sections.dart';
import 'package:kilo_app/features/today/bought_merge.dart';

import '../support/fixtures.dart';

void main() {
  group('CloseReviewRules', () {
    const rules = CloseReviewRules();
    final chicken = supply(
      closeCheck: const CloseCheck(
        base: 20,
        gapDays: 2,
        usual: 4,
        reviewBelow: 4,
      ),
    );

    test('flags a remaining below reviewBelow with the implied use', () {
      final flag = rules.flag(chicken, 2)!;
      expect(flag.consumed, 9);
      expect(flag.usual, 4);
    });

    test('accepts values at or above the threshold', () {
      expect(rules.flag(chicken, 4), isNull);
      expect(rules.flag(chicken, 30), isNull);
    });

    test('never flags without history', () {
      expect(rules.flag(supply(), 0), isNull);
    });
  });

  group('PurchaseLineRules', () {
    const rules = PurchaseLineRules();
    final onion = supply(
      id: 'onion',
      name: 'Cebolla roja',
      shelfLifeDays: 14,
      priceCheck: const PriceCheck(usual: 2.5, low: 1.5, high: 3.5),
    );
    PurchaseLineDraft line({double? quantity = 2, double? cost = 5}) =>
        PurchaseLineDraft(
          id: 1,
          spoken: 'cebolla',
          supply: onion,
          quantity: quantity,
          cost: cost,
        );

    test('default expiry is today plus shelf life', () {
      expect(
        rules.defaultExpiry(onion, DateTime.utc(2026, 11, 20)),
        DateTime.utc(2026, 12, 4),
      );
    });

    test('flags a unit price outside the usual range', () {
      expect(rules.priceFlag(line()), isNull);
      final flag = rules.priceFlag(line(cost: 8))!;
      expect(flag.unitPrice, 4);
      expect(flag.usual, 2.5);
      expect(rules.priceFlag(line(cost: 2)), isNotNull);
    });

    test('a line needs supply, measure, quantity, cost and price ok', () {
      expect(
        rules.problem(const PurchaseLineDraft(id: 1, spoken: 'limón')),
        LineProblem.unresolved,
      );
      expect(
        rules.problem(
          PurchaseLineDraft(
            id: 1,
            spoken: 'tomate',
            supply: onion,
            phrase: 'medio balde',
          ),
        ),
        LineProblem.measure,
      );
      expect(rules.problem(line(quantity: null)), LineProblem.quantity);
      expect(rules.problem(line(quantity: 0)), LineProblem.quantity);
      expect(rules.problem(line(cost: null)), LineProblem.cost);
      expect(rules.problem(line(cost: 8)), LineProblem.price);
      expect(rules.isValid(line(cost: 8).withPriceConfirmed()), isTrue);
      expect(rules.isValid(line()), isTrue);
    });

    test('editing the quantity asks to confirm the price again', () {
      final confirmed = line(cost: 8).withPriceConfirmed();
      expect(confirmed.withQuantity(3).priceConfirmed, isFalse);
    });
  });

  test('BoughtMerge trusts the server or the local check', () {
    const merge = BoughtMerge();
    final chicken = supply();
    expect(merge.isBought(suggestion(chicken, bought: true), {}), isTrue);
    expect(merge.isBought(suggestion(chicken), {chicken.id}), isTrue);
    expect(merge.isBought(suggestion(chicken), {'other'}), isFalse);
  });

  group('SupplySections', () {
    const sections = SupplySections();
    final supplies = [
      supply(id: 'a', name: 'Limón sutil', categoryId: 'produce'),
      supply(id: 'b', name: 'Pollo entero', expiresInDays: 1),
      supply(
        id: 'c',
        name: 'Ají limo',
        categoryId: 'produce',
        expiresInDays: 0,
      ),
    ];
    final categories = [
      category,
      const SupplyCategory(
        id: 'produce',
        name: 'Verduras y frutas',
        purchaseIntervalDays: 3,
        monthlySpend: 800,
        critical: true,
      ),
    ];

    test('groups by category in category order, sorted by name', () {
      final grouped = sections.group(supplies, categories, '');
      expect(grouped.map((s) => s.title), ['Proteínas', 'Verduras y frutas']);
      expect(grouped.last.supplies.map((s) => s.name), [
        'Ají limo',
        'Limón sutil',
      ]);
    });

    test('search ignores case and accents', () {
      final grouped = sections.group(supplies, categories, 'LIMON');
      expect(grouped.single.supplies.single.id, 'a');
      expect(sections.group(supplies, categories, 'zzz'), isEmpty);
    });

    test('expiring lists the most urgent first', () {
      expect(sections.expiring(supplies).map((s) => s.id), ['c', 'b']);
    });
  });

  test('PeakDays names the two busiest days', () {
    const peaks = PeakDays();
    expect(
      peaks.sentence([
        ForecastDay(day: DateTime.utc(2026, 11, 16), amount: 3),
        ForecastDay(day: DateTime.utc(2026, 11, 20), amount: 9),
        ForecastDay(day: DateTime.utc(2026, 11, 21), amount: 7),
      ]),
      'Se usa más el viernes y el sábado.',
    );
    expect(
      peaks.sentence([ForecastDay(day: DateTime.utc(2026, 11, 16), amount: 0)]),
      isNull,
    );
  });

  test('VoiceKind defaults to the close at night', () {
    expect(VoiceKind.forTime(DateTime(2026, 11, 16, 18)), VoiceKind.close);
    expect(VoiceKind.forTime(DateTime(2026, 11, 16, 2)), VoiceKind.close);
    expect(VoiceKind.forTime(DateTime(2026, 11, 16, 9)), VoiceKind.purchase);
  });
}
