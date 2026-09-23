import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/engine.dart';
import '../domain/models.dart';
import '../domain/seed.dart';

class PurchaseLine {
  const PurchaseLine(this.supplyId, this.quantity, this.cost, this.expiresOn);

  final String supplyId;
  final double quantity;
  final double cost;
  final DateTime expiresOn;
}

class KiloStore extends ChangeNotifier {
  KiloStore(this._prefs, this.data, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const _key = 'kilo.v1';

  final SharedPreferences _prefs;
  final DateTime Function() _clock;
  KiloData data;
  Engine? _engine;

  static Future<KiloStore> load({DateTime Function()? clock}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final now = businessDate((clock ?? DateTime.now)());
    final data = raw == null
        ? seedData(now)
        : KiloData.fromJson(jsonDecode(raw) as Map<String, Object?>);
    final store = KiloStore(prefs, data, clock: clock);
    if (raw == null) await store._save();
    return store;
  }

  DateTime get today => businessDate(_clock());

  Engine get engine {
    final e = _engine;
    if (e != null && e.today == today) return e;
    return _engine = Engine(data, today);
  }

  Future<void> _save() => _prefs.setString(_key, jsonEncode(data.toJson()));

  void _changed() {
    _engine = null;
    _save();
    notifyListeners();
  }

  bool isBought(String supplyId) =>
      data.boughtByDay[dayKey(today)]?.contains(supplyId) ?? false;

  void toggleBought(String supplyId) {
    final set = data.boughtByDay.putIfAbsent(dayKey(today), () => {});
    if (!set.remove(supplyId)) set.add(supplyId);
    _changed();
  }

  List<SupplyInfo> closeSupplies() => [
    for (final s in data.supplies)
      if (s.critical || _daysSinceRecorded(s.id) >= 7) s,
  ];

  int _daysSinceRecorded(String supplyId) {
    final real = engine.records(supplyId).where((r) => !r.isClosed);
    return real.isEmpty ? 999 : today.difference(real.last.date).inDays;
  }

  void saveClose(Map<String, double> remaining) {
    data.stock.removeWhere(
      (r) => r.date == today && remaining.containsKey(r.supplyId),
    );
    data.stock.addAll([
      for (final e in remaining.entries) StockRecord(e.key, today, e.value),
    ]);
    _changed();
  }

  void markNoConsumption() {
    data.stock.removeWhere((r) => r.date == today);
    data.stock.addAll([
      for (final s in data.supplies) StockRecord.closed(s.id, today),
    ]);
    _changed();
  }

  void savePurchase(List<PurchaseLine> lines) {
    final stamp = _clock().microsecondsSinceEpoch;
    data.lots.addAll([
      for (final (i, l) in lines.indexed)
        Lot(
          id: 'p$stamp-$i',
          supplyId: l.supplyId,
          purchasedOn: today,
          quantity: l.quantity,
          cost: l.cost,
          expiresOn: l.expiresOn,
        ),
    ]);
    data.boughtByDay
        .putIfAbsent(dayKey(today), () => {})
        .addAll(lines.map((l) => l.supplyId));
    _changed();
  }

  void setCritical(String supplyId, bool critical) {
    final i = data.supplies.indexWhere((s) => s.id == supplyId);
    data.supplies[i] = data.supplies[i].copyWith(critical: critical);
    _changed();
  }

  void resetDemo() {
    data = seedData(today);
    _changed();
  }
}

class KiloScope extends InheritedNotifier<KiloStore> {
  const KiloScope({super.key, required KiloStore store, required super.child})
    : super(notifier: store);

  static KiloStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KiloScope>()!.notifier!;
}
