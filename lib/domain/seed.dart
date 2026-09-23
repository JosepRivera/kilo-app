import 'dart:math' as math;

import 'engine.dart';
import 'models.dart';

class _Plan {
  const _Plan(this.info, this.week, this.startDaysAgo);

  final SupplyInfo info;
  final List<double> week;
  final int startDaysAgo;
}

const seedCategories = [
  CategoryInfo(
    id: 'protein',
    name: 'Proteínas',
    purchaseIntervalDays: 3,
    monthlySpend: 3000,
  ),
  CategoryInfo(
    id: 'produce',
    name: 'Verduras y frutas',
    purchaseIntervalDays: 3,
    monthlySpend: 1800,
  ),
  CategoryInfo(
    id: 'grocery',
    name: 'Granos y abarrotes',
    purchaseIntervalDays: 10,
    monthlySpend: 900,
  ),
  CategoryInfo(
    id: 'seasoning',
    name: 'Condimentos y especias',
    purchaseIntervalDays: 14,
    monthlySpend: 150,
  ),
  CategoryInfo(
    id: 'dairy',
    name: 'Lácteos y huevos',
    purchaseIntervalDays: 4,
    monthlySpend: 600,
  ),
];

SupplyInfo _s(
  String id,
  String name,
  String unit,
  String category,
  String? icon,
  int shelf,
  double price, {
  bool critical = true,
  Map<String, double> phrases = const {},
}) => SupplyInfo(
  id: id,
  name: name,
  unit: unit,
  categoryId: category,
  icon: icon,
  shelfLifeDays: shelf,
  referencePrice: price,
  critical: critical,
  phrases: phrases,
);

final _plans = [
  _Plan(
    _s(
      'chicken',
      'Pollo entero',
      'kg',
      'protein',
      'chicken',
      3,
      9,
      phrases: {'una jaba': 18},
    ),
    [8, 7.5, 8.5, 9, 13, 14, 6],
    60,
  ),
  _Plan(_s('beef', 'Carne de res', 'kg', 'protein', 'beef', 4, 24), [
    2.5,
    2,
    2.5,
    3,
    4,
    4.5,
    2,
  ], 60),
  _Plan(_s('fish', 'Pescado', 'kg', 'protein', 'fish', 2, 18), [
    1.5,
    1.5,
    2,
    2,
    3,
    3.5,
    1,
  ], 12),
  _Plan(
    _s(
      'potato',
      'Papa canchán',
      'kg',
      'produce',
      'potato',
      14,
      2,
      phrases: {'un saco': 50},
    ),
    [5, 5, 5.5, 6, 8, 9, 4],
    60,
  ),
  _Plan(_s('onion', 'Cebolla roja', 'kg', 'produce', 'onion', 20, 2.6), [
    3,
    3,
    3,
    3.5,
    4.5,
    5,
    2.5,
  ], 60),
  _Plan(
    _s(
      'tomato',
      'Tomate',
      'kg',
      'produce',
      'tomato',
      6,
      3.5,
      phrases: {'medio balde': 5},
    ),
    [2, 2, 2, 2.5, 3, 3.5, 1.5],
    45,
  ),
  _Plan(_s('lime', 'Limón sutil', 'kg', 'produce', 'lime', 10, 5), [
    1.5,
    1.5,
    2,
    2,
    3,
    3,
    1,
  ], 45),
  _Plan(_s('cilantro', 'Culantro', 'atados', 'produce', 'cilantro', 3, 2), [
    1,
    1,
    1,
    1,
    2,
    2,
    1,
  ], 9),
  _Plan(_s('chili', 'Ají amarillo', 'kg', 'produce', 'chili', 10, 8), [
    0.5,
    0.5,
    0.5,
    0.5,
    1,
    1,
    0.5,
  ], 17),
  _Plan(_s('corn', 'Choclo', 'unidades', 'produce', 'corn', 5, 1.2), [
    6,
    6,
    6,
    7,
    10,
    12,
    5,
  ], 6),
  _Plan(
    _s('rice', 'Arroz', 'kg', 'grocery', 'rice', 365, 4.2, critical: false),
    [4, 4, 4, 4.5, 6, 6.5, 3],
    60,
  ),
  _Plan(
    _s(
      'oil',
      'Aceite vegetal',
      'litros',
      'grocery',
      'oil',
      365,
      8,
      critical: false,
      phrases: {'una lata': 18},
    ),
    [1.5, 1.5, 1.5, 2, 2.5, 3, 1],
    60,
  ),
  _Plan(
    _s('legumes', 'Menestras', 'kg', 'grocery', null, 365, 7, critical: false),
    [0.8, 0.8, 1, 1, 1.2, 1.2, 0.5],
    20,
  ),
  _Plan(
    _s('salt', 'Sal', 'kg', 'seasoning', 'salt', 730, 1.5, critical: false),
    [0.2, 0.2, 0.2, 0.2, 0.3, 0.3, 0.1],
    60,
  ),
  _Plan(
    _s('garlic', 'Ajo', 'kg', 'seasoning', 'garlic', 30, 10, critical: false),
    [0.3, 0.3, 0.3, 0.3, 0.4, 0.5, 0.2],
    50,
  ),
  _Plan(_s('egg', 'Huevos', 'unidades', 'dairy', 'egg', 21, 0.5), [
    20,
    20,
    22,
    22,
    30,
    34,
    15,
  ], 38),
  _Plan(_s('cheese', 'Queso fresco', 'kg', 'dairy', 'cheese', 7, 18), [
    0.4,
    0.4,
    0.5,
    0.5,
    0.7,
    0.8,
    0.3,
  ], 22),
];

KiloData seedData(DateTime today) {
  final rng = math.Random(7);
  double noise(double spread) => 1 + (rng.nextDouble() * 2 - 1) * spread;
  final start = DateTime(today.year, today.month, today.day - 60);
  final closedDay = DateTime(today.year, today.month, today.day - 20);
  final forgotten = DateTime(today.year, today.month, today.day - 9);

  final stock = <StockRecord>[];
  final lots = <Lot>[];
  final onHand = <String, List<(Lot, double)>>{
    for (final p in _plans) p.info.id: [],
  };
  final lastPurchase = <String, DateTime>{};
  var lotId = 0;

  for (
    var d = start;
    d.isBefore(today);
    d = DateTime(d.year, d.month, d.day + 1)
  ) {
    final active = _plans.where(
      (p) => !d.isBefore(
        DateTime(today.year, today.month, today.day - p.startDaysAgo),
      ),
    );
    final closed = d == closedDay;

    for (final p in active) {
      onHand[p.info.id]!.removeWhere((e) => e.$1.expiresOn.isBefore(d));
    }

    if (!closed) {
      for (final c in seedCategories) {
        final last = lastPurchase[c.id];
        if (last != null &&
            d.difference(last).inDays < c.purchaseIntervalDays) {
          continue;
        }
        var bought = false;
        for (final p in active.where((p) => p.info.categoryId == c.id)) {
          final held = onHand[p.info.id]!.fold(0.0, (t, e) => t + e.$2);
          final need = [
            for (var k = 0; k < c.purchaseIntervalDays; k++)
              p.week[DateTime(d.year, d.month, d.day + k).weekday - 1],
          ].fold(0.0, (a, b) => a + b);
          final qty = roundUpToStep(need * 1.3 - held, p.info.unit);
          if (qty <= 0) continue;
          final lot = Lot(
            id: 'seed${lotId++}',
            supplyId: p.info.id,
            purchasedOn: d,
            quantity: qty,
            cost: double.parse(
              (qty * p.info.referencePrice * noise(0.08)).toStringAsFixed(2),
            ),
            expiresOn: DateTime(d.year, d.month, d.day + p.info.shelfLifeDays),
          );
          lots.add(lot);
          onHand[p.info.id]!.add((lot, qty));
          bought = true;
        }
        if (bought) lastPurchase[c.id] = d;
      }
    }

    for (final p in active) {
      final queue = onHand[p.info.id]!;
      if (!closed) {
        var use = p.week[d.weekday - 1] * noise(0.15);
        for (var k = 0; k < queue.length && use > 0; k++) {
          final take = math.min(use, queue[k].$2);
          queue[k] = (queue[k].$1, queue[k].$2 - take);
          use -= take;
        }
        queue.removeWhere((e) => e.$2 <= 0.001);
      }
      final remaining = double.parse(
        queue.fold(0.0, (t, e) => t + e.$2).toStringAsFixed(1),
      );
      final recordToday =
          closed ||
          d == DateTime(today.year, today.month, today.day - p.startDaysAgo) ||
          d == today;
      if (closed) {
        stock.add(StockRecord.closed(p.info.id, d));
      } else if (p.info.critical
          ? d != forgotten
          : d.weekday == DateTime.monday || recordToday) {
        stock.add(StockRecord(p.info.id, d, remaining));
      }
    }
  }

  return KiloData(
    categories: [...seedCategories],
    supplies: [for (final p in _plans) p.info],
    stock: stock,
    lots: lots,
  );
}
