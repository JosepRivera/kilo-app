import 'dart:math' as math;

import 'models.dart';

const coldStartDays = 28;
const serviceZ = 1.28;
const bufferFloor = 0.10;
const bufferCeiling = 0.60;
const anomalyFactor = 3.0;
const anomalyFloorSoles = 10.0;
const priceTolerance = 0.40;
const estimatedDayWeight = 0.5;
const openingLotPrefix = 'opening-';

class Consumption {
  const Consumption(this.amount, {this.estimated = false, this.closed = false});

  final double amount;
  final bool estimated;
  final bool closed;
}

class Recommendation {
  const Recommendation({
    required this.supply,
    required this.toBuy,
    required this.onHand,
    required this.needed,
    required this.horizonDays,
  });

  final SupplyInfo supply;
  final double toBuy;
  final double onHand;
  final double needed;
  final int horizonDays;
}

class LotState {
  const LotState(this.lot, this.remaining);

  final Lot lot;
  final double remaining;
}

class WasteEvent {
  const WasteEvent(this.date, this.supplyId, this.quantity, this.soles);

  final DateTime date;
  final String supplyId;
  final double quantity;
  final double soles;
}

class ExpiryAlert {
  const ExpiryAlert(this.supply, this.lot, this.daysLeft);

  final SupplyInfo supply;
  final LotState lot;
  final int daysLeft;
}

class AnomalyFlag {
  const AnomalyFlag(this.consumed, this.usual);

  final double consumed;
  final double usual;
}

class PriceFlag {
  const PriceFlag(this.unitPrice, this.usual);

  final double unitPrice;
  final double usual;
}

DateTime _plus(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);

int _daysBetween(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

double median(List<double> xs) {
  if (xs.isEmpty) return 0;
  final s = [...xs]..sort();
  final m = s.length ~/ 2;
  return s.length.isOdd ? s[m] : (s[m - 1] + s[m]) / 2;
}

double _mean(Iterable<double> xs) =>
    xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;

double roundUpToStep(double v, String unit) {
  final step = unit == 'kg' || unit == 'litros' ? 0.5 : 1.0;
  return (v / step).ceil() * step;
}

class Engine {
  Engine(this.data, this.today);

  final KiloData data;
  final DateTime today;

  final _consumption = <String, Map<DateTime, Consumption>>{};
  final _lots = <String, (List<LotState>, List<WasteEvent>)>{};

  List<StockRecord> records(String id) =>
      data.stock.where((r) => r.supplyId == id).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  List<Lot> lotsOf(String id) =>
      data.lots.where((l) => l.supplyId == id).toList()
        ..sort((a, b) => a.purchasedOn.compareTo(b.purchasedOn));

  double purchasesIn(
    String id,
    DateTime afterExclusive,
    DateTime untilInclusive,
  ) => data.lots
      .where(
        (l) =>
            l.supplyId == id &&
            l.purchasedOn.isAfter(afterExclusive) &&
            !l.purchasedOn.isAfter(untilInclusive),
      )
      .fold(0.0, (t, l) => t + l.quantity);

  Map<DateTime, Consumption> consumption(String id) => _consumption.putIfAbsent(
    id,
    () {
      final out = <DateTime, Consumption>{};
      final recs = records(id);
      final first = recs.indexWhere((r) => !r.isClosed);
      if (first < 0) return out;
      var prevStock = recs[first].remaining!;
      var prevDate = recs[first].date;
      for (final r in recs.skip(first + 1)) {
        final bought = purchasesIn(id, prevDate, r.date);
        if (r.isClosed) {
          prevStock += bought;
          out[r.date] = const Consumption(0, closed: true);
          prevDate = r.date;
          continue;
        }
        final total = math.max(0.0, prevStock + bought - r.remaining!);
        final gap = _daysBetween(prevDate, r.date);
        if (gap <= 1) {
          out[r.date] = Consumption(total);
        } else {
          for (var k = 1; k <= gap; k++) {
            out[_plus(prevDate, k)] = Consumption(total / gap, estimated: true);
          }
        }
        prevStock = r.remaining!;
        prevDate = r.date;
      }
      return out;
    },
  );

  int realDays(String id) =>
      consumption(id).values
          .fold(0.0, (t, c) => t + (c.estimated ? estimatedDayWeight : 1))
          .floor();

  bool isLearning(String id) => realDays(id) < coldStartDays;

  double currentStock(String id) {
    if (lotsOf(id).isNotEmpty) {
      return activeLots(id).fold(0.0, (t, l) => t + l.remaining);
    }
    final recs = records(id).where((r) => !r.isClosed).toList();
    return recs.isEmpty ? 0 : recs.last.remaining!;
  }

  double coldStartEstimate(String id) {
    final s = data.supply(id);
    final siblings = data.supplies
        .where((x) => x.categoryId == s.categoryId)
        .length;
    return data.category(s.categoryId).monthlySpend /
        siblings /
        30 /
        s.referencePrice;
  }

  List<MapEntry<DateTime, Consumption>> _window(String id, int days) {
    final from = _plus(today, -days);
    return consumption(id).entries
        .where((e) => !e.key.isBefore(from) && e.key.isBefore(today))
        .toList();
  }

  double _empirical(String id, int weekday) {
    final w = _window(id, 28);
    final same = w
        .where((e) => e.key.weekday == weekday)
        .map((e) => e.value.amount)
        .toList();
    if (same.length >= 2) return _mean(same);
    return _mean(w.map((e) => e.value.amount));
  }

  double forecast(String id, DateTime d) {
    final real = realDays(id);
    final cold = coldStartEstimate(id);
    if (real == 0) return cold;
    final weight = math.max(0.0, 1 - real / coldStartDays);
    return weight * cold + (1 - weight) * _empirical(id, d.weekday);
  }

  double errorEstimate(String id) {
    final w = _window(id, 28).where((e) => !e.value.closed).toList();
    if (w.length < 7) return 0.3 * forecast(id, today);
    final residuals = [
      for (final e in w) e.value.amount - _empirical(id, e.key.weekday),
    ];
    final m = _mean(residuals);
    return math.sqrt(_mean(residuals.map((r) => (r - m) * (r - m))));
  }

  Recommendation recommend(String id) {
    final s = data.supply(id);
    final h = data.category(s.categoryId).purchaseIntervalDays;
    final demand = [for (var k = 0; k < h; k++) forecast(id, _plus(today, k))]
        .fold(0.0, (a, b) => a + b);
    final buffer = (serviceZ * errorEstimate(id) * math.sqrt(h)).clamp(
      bufferFloor * demand,
      bufferCeiling * demand,
    );
    final onHand = currentStock(id);
    final raw = demand + buffer - onHand;
    return Recommendation(
      supply: s,
      toBuy: raw <= 0 ? 0 : roundUpToStep(raw, s.unit),
      onHand: onHand,
      needed: demand + buffer,
      horizonDays: h,
    );
  }

  DateTime? lastPurchase(String categoryId) {
    final ids = {
      for (final s in data.supplies.where((s) => s.categoryId == categoryId))
        s.id,
    };
    final dates =
        data.lots
            .where((l) => ids.contains(l.supplyId))
            .map((l) => l.purchasedOn)
            .toList()
          ..sort();
    return dates.isEmpty ? null : dates.last;
  }

  bool isDue(String categoryId) {
    final last = lastPurchase(categoryId);
    if (last == null) return true;
    if (_daysBetween(last, today) == 0) return true;
    return _daysBetween(last, today) >=
        data.category(categoryId).purchaseIntervalDays;
  }

  (List<LotState>, List<WasteEvent>) _simulateLots(String id) =>
      _lots.putIfAbsent(id, () {
        final lots = lotsOf(id);
        if (lots.isEmpty) return (const <LotState>[], const <WasteEvent>[]);
        final counted = {
          for (final r in records(id))
            if (!r.isClosed) r.date: r.remaining!,
        };
        final queue = <(Lot, double)>[];
        final waste = <WasteEvent>[];
        var i = 0;
        final firstCount = counted.keys.fold<DateTime?>(
          null,
          (a, b) => a == null || b.isBefore(a) ? b : a,
        );
        final start =
            firstCount != null && firstCount.isBefore(lots.first.purchasedOn)
            ? firstCount
            : lots.first.purchasedOn;
        for (var d = start; !d.isAfter(today); d = _plus(d, 1)) {
          queue.removeWhere((e) {
            if (!e.$1.expiresOn.isBefore(d) || e.$2 <= 0.001) return false;
            waste.add(WasteEvent(d, id, e.$2, e.$2 * e.$1.unitPrice));
            return true;
          });
          while (i < lots.length && !lots[i].purchasedOn.isAfter(d)) {
            queue.add((lots[i], lots[i].quantity));
            i++;
          }
          final remaining = counted[d];
          if (remaining == null) continue;
          var used = queue.fold(0.0, (t, e) => t + e.$2) - remaining;
          if (used < -0.001) {
            final price = data.supply(id).referencePrice;
            queue.insert(0, (
              Lot(
                id: '$openingLotPrefix$id-${dayKey(d)}',
                supplyId: id,
                purchasedOn: d,
                quantity: -used,
                cost: -used * price,
                expiresOn: DateTime(9999),
              ),
              -used,
            ));
          }
          for (var k = 0; k < queue.length && used > 0; k++) {
            final take = math.min(used, queue[k].$2);
            queue[k] = (queue[k].$1, queue[k].$2 - take);
            used -= take;
          }
          queue.removeWhere((e) => e.$2 <= 0.001);
        }
        return ([for (final e in queue) LotState(e.$1, e.$2)], waste);
      });

  List<LotState> activeLots(String id) => _simulateLots(id).$1;

  List<WasteEvent> waste() => [
    for (final s in data.supplies) ..._simulateLots(s.id).$2,
  ];

  List<ExpiryAlert> expiryAlerts() => [
    for (final s in data.supplies)
      for (final l in activeLots(s.id))
        if (_daysBetween(today, l.lot.expiresOn) <= 1)
          ExpiryAlert(s, l, _daysBetween(today, l.lot.expiresOn)),
  ]..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

  Map<DateTime, double> monthlyWaste() {
    final out = <DateTime, double>{};
    for (final w in waste()) {
      final m = DateTime(w.date.year, w.date.month);
      out[m] = (out[m] ?? 0) + w.soles;
    }
    return out;
  }

  String lotLabel(Lot l) {
    final ago = _daysBetween(l.purchasedOn, today);
    if (ago == 0) return 'de hoy';
    if (ago == 1) return 'de ayer';
    return 'del ${const ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'][l.purchasedOn.weekday - 1]}';
  }

  double expectedRemainingTonight(String id) =>
      math.max(0, currentStock(id) - forecast(id, today));

  AnomalyFlag? checkClose(String id, double remaining) {
    final recs = records(id).where((r) => r.date.isBefore(today)).toList();
    final lastReal = recs.lastIndexWhere((r) => !r.isClosed);
    if (lastReal < 0) return null;
    final prevDate = recs[lastReal].date;
    final prevStock = recs[lastReal].remaining!;
    final gap = math.max(1, _daysBetween(prevDate, today));
    final consumed =
        math.max(
          0.0,
          prevStock + purchasesIn(id, prevDate, today) - remaining,
        ) /
        gap;
    final w28 = _window(id, 28).where((e) => !e.value.closed).toList();
    final sameDay = w28
        .where((e) => e.key.weekday == today.weekday)
        .map((e) => e.value.amount)
        .toList();
    final usual = sameDay.length >= 4
        ? median(sameDay)
        : median(
            _window(
              id,
              14,
            ).where((e) => !e.value.closed).map((e) => e.value.amount).toList(),
          );
    if (usual <= 0) return null;
    final excessSoles = (consumed - usual) * data.supply(id).referencePrice;
    return consumed > anomalyFactor * usual && excessSoles >= anomalyFloorSoles
        ? AnomalyFlag(consumed, usual)
        : null;
  }

  PriceFlag? checkPrice(String id, double unitPrice) {
    final prices = lotsOf(id).map((l) => l.unitPrice).toList();
    if (prices.isEmpty) return null;
    final usual = median(prices);
    return (unitPrice - usual).abs() / usual > priceTolerance
        ? PriceFlag(unitPrice, usual)
        : null;
  }
}
