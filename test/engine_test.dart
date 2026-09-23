import 'package:flutter_test/flutter_test.dart';
import 'package:kilo_app/domain/engine.dart';
import 'package:kilo_app/domain/models.dart';

DateTime d(int dayOfSept) => DateTime(2026, 9, dayOfSept);

const chicken = SupplyInfo(
  id: 'chicken',
  name: 'Pollo entero',
  unit: 'kg',
  categoryId: 'protein',
  shelfLifeDays: 3,
  referencePrice: 9,
);

const protein = CategoryInfo(
  id: 'protein',
  name: 'Proteínas',
  purchaseIntervalDays: 3,
  monthlySpend: 2700,
);

Lot lot(String id, int on, double qty, {double cost = 90, int? expires}) => Lot(
  id: id,
  supplyId: 'chicken',
  purchasedOn: d(on),
  quantity: qty,
  cost: cost,
  expiresOn: d(expires ?? on + 3),
);

KiloData data({
  List<StockRecord> stock = const [],
  List<Lot> lots = const [],
}) => KiloData(
  categories: const [protein],
  supplies: const [chicken],
  stock: [...stock],
  lots: [...lots],
);

void main() {
  test('business date: before 6am belongs to the previous day', () {
    expect(businessDate(DateTime(2026, 9, 24, 1, 30)), d(23));
    expect(businessDate(DateTime(2026, 9, 24, 6)), d(24));
  });

  test('consumption adds purchases made inside the window', () {
    final e = Engine(
      data(
        stock: [
          StockRecord('chicken', d(1), 10),
          StockRecord('chicken', d(2), 12),
        ],
        lots: [lot('a', 2, 10)],
      ),
      d(3),
    );
    expect(e.consumption('chicken')[d(2)]!.amount, 8);
    expect(e.consumption('chicken')[d(2)]!.estimated, isFalse);
  });

  test('forgotten days are spread evenly, marked estimated and weigh half', () {
    final e = Engine(
      data(
        stock: [
          StockRecord('chicken', d(1), 15),
          StockRecord('chicken', d(4), 6),
        ],
      ),
      d(5),
    );
    final c = e.consumption('chicken');
    for (final day in [2, 3, 4]) {
      expect(c[d(day)]!.amount, 3);
      expect(c[d(day)]!.estimated, isTrue);
    }
    expect(e.realDays('chicken'), 1);
  });

  test('a closed day is a real zero and keeps the stock', () {
    final e = Engine(
      data(
        stock: [
          StockRecord('chicken', d(1), 10),
          StockRecord.closed('chicken', d(2)),
          StockRecord('chicken', d(3), 6),
        ],
      ),
      d(4),
    );
    final c = e.consumption('chicken');
    expect(c[d(2)]!.amount, 0);
    expect(c[d(2)]!.closed, isTrue);
    expect(c[d(3)]!.amount, 4);
    expect(e.realDays('chicken'), 2);
  });

  test('current stock is the last close plus later purchases', () {
    final e = Engine(
      data(stock: [StockRecord('chicken', d(1), 5)], lots: [lot('a', 2, 20)]),
      d(2),
    );
    expect(e.currentStock('chicken'), 25);
  });

  test('cold start splits declared category spend evenly', () {
    final e = Engine(data(), d(1));
    expect(e.coldStartEstimate('chicken'), closeTo(2700 / 1 / 30 / 9, 1e-9));
    expect(e.forecast('chicken', d(1)), closeTo(10, 1e-9));
  });

  test('recommendation keeps the buffer between 10% and 60% of demand', () {
    final e = Engine(data(stock: [StockRecord('chicken', d(1), 0)]), d(2));
    final r = e.recommend('chicken');
    expect(r.needed, greaterThanOrEqualTo(30 * 1.1 - 1e-9));
    expect(r.needed, lessThanOrEqualTo(30 * 1.6 + 1e-9));
    expect(r.toBuy, roundUpToStep(r.needed, 'kg'));
  });

  test('nothing to buy when stock already covers the horizon', () {
    final e = Engine(data(stock: [StockRecord('chicken', d(1), 100)]), d(2));
    expect(e.recommend('chicken').toBuy, 0);
  });

  test(
    'FIFO consumes the oldest lot first and flags the one about to expire',
    () {
      final e = Engine(
        data(
          stock: [
            StockRecord('chicken', d(1), 0),
            StockRecord('chicken', d(3), 12),
          ],
          lots: [lot('a', 2, 8, expires: 4), lot('b', 3, 8, expires: 6)],
        ),
        d(4),
      );
      final active = e.activeLots('chicken');
      expect(active.map((l) => l.lot.id), ['a', 'b']);
      expect(active.first.remaining, closeTo(4, 1e-9));
      expect(active.last.remaining, 8);
      expect(e.expiryAlerts().single.lot.lot.id, 'a');
    },
  );

  test('a lot left past its expiry becomes waste at its unit cost', () {
    final e = Engine(
      data(
        stock: [
          StockRecord('chicken', d(1), 0),
          StockRecord('chicken', d(2), 10),
        ],
        lots: [lot('a', 2, 10, cost: 90, expires: 3)],
      ),
      d(5),
    );
    final w = e.waste();
    expect(w, hasLength(1));
    expect(w.single.soles, closeTo(90, 1e-9));
    expect(e.monthlyWaste()[DateTime(2026, 9)], closeTo(90, 1e-9));
  });

  test('anomaly: over 3x the usual and worth at least S/10', () {
    final stock = [
      for (var k = 1; k <= 15; k++)
        StockRecord('chicken', d(k), 100 - 4.0 * (k - 1)),
    ];
    final e = Engine(data(stock: stock), d(16));
    expect(e.checkClose('chicken', 44 - 4), isNull);
    final flag = e.checkClose('chicken', 44 - 13);
    expect(flag, isNotNull);
    expect(flag!.consumed, 13);
    expect(flag.usual, 4);
  });

  test('price flag when the unit price leaves the usual range', () {
    final e = Engine(
      data(lots: [lot('a', 1, 10, cost: 90), lot('b', 2, 10, cost: 92)]),
      d(3),
    );
    expect(e.checkPrice('chicken', 9.2), isNull);
    expect(e.checkPrice('chicken', 14), isNotNull);
  });

  test('json round trip keeps everything', () {
    final original = data(
      stock: [
        StockRecord('chicken', d(1), 3),
        StockRecord.closed('chicken', d(2)),
      ],
      lots: [lot('a', 1, 10)],
    )..boughtByDay['2026-09-01'] = {'chicken'};
    final copy = KiloData.fromJson(original.toJson());
    expect(copy.stock.last.isClosed, isTrue);
    expect(copy.lots.single.cost, 90);
    expect(copy.boughtByDay['2026-09-01'], {'chicken'});
  });
}
