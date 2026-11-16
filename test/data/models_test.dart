import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kilo_app/data/json.dart';
import 'package:kilo_app/data/models/catalog_resolution.dart';
import 'package:kilo_app/data/models/close_draft.dart';
import 'package:kilo_app/data/models/new_supply.dart';
import 'package:kilo_app/data/models/purchase_line.dart';
import 'package:kilo_app/data/models/recent_day_kind.dart';
import 'package:kilo_app/data/models/registration.dart';
import 'package:kilo_app/data/models/resolution_kind.dart';
import 'package:kilo_app/data/models/savings.dart';
import 'package:kilo_app/data/models/supply.dart';
import 'package:kilo_app/data/models/supply_category.dart';
import 'package:kilo_app/data/models/supply_detail.dart';
import 'package:kilo_app/data/models/today_overview.dart';
import 'package:kilo_app/data/models/voice_draft.dart';

const supplyView = '''
{
  "id": "uuid", "name": "Pollo entero", "unit": "kg", "categoryId": "cat",
  "icon": "chicken", "critical": true, "shelfLifeDays": 3, "referencePrice": 9.5,
  "phrases": { "medio balde": 6 },
  "stock": 12, "realDays": 9, "learning": true, "expiresInDays": 0,
  "dueForClose": true, "expectedRemaining": 8,
  "closeCheck": { "base": 12, "gapDays": 1, "usual": 4, "reviewBelow": 0 },
  "priceCheck": { "usual": 10, "low": 6, "high": 14 }
}''';

const recommendation = '''
{ "toBuy": 27, "onHand": 12, "demand": 30, "buffer": 8.9,
  "horizonDays": 3, "typicalError": 4 }''';

Json decode(String source) => jsonDecode(source) as Json;

void main() {
  test('SupplyView decodes every field', () {
    final supply = Supply.fromJson(decode(supplyView));
    expect(supply.name, 'Pollo entero');
    expect(supply.phrases, {'medio balde': 6.0});
    expect(supply.expiresInDays, 0);
    expect(supply.closeCheck!.reviewBelow, 0);
    expect(supply.closeCheck!.gapDays, 1);
    expect(supply.priceCheck!.high, 14);
    expect(supply.expectedRemaining, 8);
  });

  test('SupplyView accepts null icon, expiry and checks', () {
    final json = decode(supplyView)
      ..['icon'] = null
      ..['expiresInDays'] = null
      ..['closeCheck'] = null
      ..['priceCheck'] = null;
    final supply = Supply.fromJson(json);
    expect(supply.icon, isNull);
    expect(supply.expiresInDays, isNull);
    expect(supply.closeCheck, isNull);
    expect(supply.priceCheck, isNull);
  });

  test('supply detail decodes week, recent and lots', () {
    final json = decode(supplyView)
      ..['recommendation'] = decode(recommendation)
      ..['week'] = [
        {'day': '2026-11-16', 'amount': 9.8},
      ]
      ..['recent'] = [
        {'day': '2026-11-15', 'amount': 10, 'kind': 'estimated'},
      ]
      ..['lots'] = [
        {
          'id': 'lot',
          'purchasedOn': '2026-11-14',
          'expiresOn': '2026-11-17',
          'remaining': 6,
          'daysLeft': 1,
        },
      ];
    final detail = SupplyDetail.fromJson(json);
    expect(detail.recommendation.toBuy, 27);
    expect(detail.recommendation.coveredFraction, closeTo(12 / 38.9, 1e-9));
    expect(detail.week.single.day, DateTime.utc(2026, 11, 16));
    expect(detail.recent.single.kind, RecentDayKind.estimated);
    expect(detail.lots.single.daysLeft, 1);
  });

  test('today decodes alerts, purchases and covered', () {
    final overview = TodayOverview.fromJson(
      decode('''
{
  "day": "2026-11-16",
  "alerts": [{ "supply": $supplyView, "daysLeft": 0, "remaining": 6,
               "lots": [{ "purchasedOn": "2026-11-13", "remaining": 6, "daysLeft": 0 }] }],
  "toBuy": [{ "supply": $supplyView, "recommendation": $recommendation, "bought": false }],
  "covered": [$supplyView]
}'''),
    );
    expect(overview.day, DateTime.utc(2026, 11, 16));
    expect(overview.alerts.single.lots.single.purchasedOn.day, 13);
    expect(overview.toBuy.single.bought, isFalse);
    expect(overview.covered, hasLength(1));
    expect(overview.isEmpty, isFalse);
  });

  test('savings decodes months and top wasted', () {
    final savings = Savings.fromJson(
      decode('''
{ "months": [{ "month": "2026-08", "soles": 0 }], "current": 200, "previous": 250,
  "topWasted": [{ "supply": $supplyView, "soles": 80 }] }'''),
    );
    expect(savings.months.single.month, '2026-08');
    expect(savings.previous, 250);
    expect(savings.topWasted.single.soles, 80);
  });

  test('catalog resolution covers its three kinds', () {
    final exact = CatalogResolution.fromJson(
      decode(
        '{"kind":"exact","candidate":{"supplyId":"s","name":"Pollo entero","unit":"kg","category":null}}',
      ),
    );
    final ambiguous = CatalogResolution.fromJson(
      decode(
        '{"kind":"ambiguous","candidates":[{"supplyId":null,"name":"Limón sutil","unit":"kg","category":"produce"},{"supplyId":null,"name":"Lima persa","unit":"kg","category":"produce"}]}',
      ),
    );
    final unknown = CatalogResolution.fromJson(decode('{"kind":"unknown"}'));
    expect(exact.kind, ResolutionKind.exact);
    expect(exact.candidates.single.supplyId, 's');
    expect(ambiguous.candidates.map((c) => c.name), [
      'Limón sutil',
      'Lima persa',
    ]);
    expect(ambiguous.candidates.first.category, 'produce');
    expect(unknown.candidates, isEmpty);
  });

  test('voice draft decodes the README example', () {
    final draft = VoiceDraft.fromJson(
      decode(
        '''
{ "transcript": "quedan tres kilos de pollo y medio balde de tomate",
  "items": [{ "spoken": "pollo",
    "resolution": { "kind": "exact", "candidate": { "supplyId": "uuid", "name": "Pollo entero", "unit": "kg", "category": null } },
    "quantity": 3, "phrase": null, "cost": null, "suggestedQuantity": null },
   { "spoken": "tomate", "resolution": { "kind": "unknown" },
    "quantity": null, "phrase": "medio balde", "cost": 12.5, "suggestedQuantity": 2 }] }''',
      ),
    );
    expect(draft.items.first.quantity, 3);
    expect(draft.items.last.phrase, 'medio balde');
    expect(draft.items.last.cost, 12.5);
    expect(draft.items.last.suggestedQuantity, 2);
  });

  test('registration and category decode', () {
    final registration = Registration.fromJson(
      decode(
        '{"token":"t","restaurant":{"id":"r","name":"Doña Rosa","closedWeekdays":[7]}}',
      ),
    );
    final category = SupplyCategory.fromJson(
      decode(
        '{"id":"c","name":"Proteínas","purchaseIntervalDays":3,"monthlySpend":1200,"critical":true}',
      ),
    );
    expect(registration.token, 't');
    expect(registration.restaurant.closedWeekdays, [7]);
    expect(category.monthlySpend, 1200);
  });

  test('request bodies match the contract', () {
    expect(
      PurchaseLine(
        supplyId: 's',
        quantity: 2,
        cost: 20,
        expiresOn: DateTime.utc(2026, 11, 19),
      ).toJson(),
      {'supplyId': 's', 'quantity': 2, 'cost': 20, 'expiresOn': '2026-11-19'},
    );
    expect(const NewSupply(name: 'Pollo entero').toJson(), {
      'name': 'Pollo entero',
    });
    expect(
      const NewSupply(
        name: 'Huacatay',
        unit: 'atados',
        categoryId: 'c',
        shelfLifeDays: 5,
      ).toJson(),
      {
        'name': 'Huacatay',
        'unit': 'atados',
        'categoryId': 'c',
        'shelfLifeDays': 5,
      },
    );
  });

  test('close draft round-trips through JSON', () {
    const draft = CloseDraft(
      day: '2026-11-16',
      remaining: {'s': 2.5},
      transcript: 'quedan',
    );
    final restored = CloseDraft.fromJson(decode(jsonEncode(draft.toJson())));
    expect(restored.day, draft.day);
    expect(restored.remaining, draft.remaining);
    expect(restored.transcript, draft.transcript);
  });
}
