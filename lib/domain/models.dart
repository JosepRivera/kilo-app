DateTime day(DateTime t) => DateTime(t.year, t.month, t.day);

DateTime businessDate(DateTime t) =>
    t.hour < 6 ? day(t.subtract(const Duration(days: 1))) : day(t);

String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDay(String s) => DateTime.parse(s);

class CategoryInfo {
  const CategoryInfo({
    required this.id,
    required this.name,
    required this.purchaseIntervalDays,
    required this.monthlySpend,
  });

  final String id;
  final String name;
  final int purchaseIntervalDays;
  final double monthlySpend;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'interval': purchaseIntervalDays,
    'spend': monthlySpend,
  };

  factory CategoryInfo.fromJson(Map<String, Object?> j) => CategoryInfo(
    id: j['id']! as String,
    name: j['name']! as String,
    purchaseIntervalDays: j['interval']! as int,
    monthlySpend: (j['spend']! as num).toDouble(),
  );
}

class SupplyInfo {
  const SupplyInfo({
    required this.id,
    required this.name,
    required this.unit,
    required this.categoryId,
    required this.shelfLifeDays,
    required this.referencePrice,
    this.icon,
    this.critical = true,
    this.phrases = const {},
  });

  final String id;
  final String name;
  final String unit;
  final String categoryId;
  final int shelfLifeDays;
  final double referencePrice;
  final String? icon;
  final bool critical;
  final Map<String, double> phrases;

  SupplyInfo copyWith({bool? critical}) => SupplyInfo(
    id: id,
    name: name,
    unit: unit,
    categoryId: categoryId,
    shelfLifeDays: shelfLifeDays,
    referencePrice: referencePrice,
    icon: icon,
    critical: critical ?? this.critical,
    phrases: phrases,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'unit': unit,
    'category': categoryId,
    'shelfLife': shelfLifeDays,
    'price': referencePrice,
    'icon': icon,
    'critical': critical,
    'phrases': phrases,
  };

  factory SupplyInfo.fromJson(Map<String, Object?> j) => SupplyInfo(
    id: j['id']! as String,
    name: j['name']! as String,
    unit: j['unit']! as String,
    categoryId: j['category']! as String,
    shelfLifeDays: j['shelfLife']! as int,
    referencePrice: (j['price']! as num).toDouble(),
    icon: j['icon'] as String?,
    critical: j['critical']! as bool,
    phrases: {
      for (final e in (j['phrases']! as Map<String, Object?>).entries)
        e.key: (e.value! as num).toDouble(),
    },
  );
}

class StockRecord {
  const StockRecord(this.supplyId, this.date, this.remaining);

  const StockRecord.closed(this.supplyId, this.date) : remaining = null;

  final String supplyId;
  final DateTime date;
  final double? remaining;

  bool get isClosed => remaining == null;

  Map<String, Object?> toJson() => {
    's': supplyId,
    'd': dayKey(date),
    'r': remaining,
  };

  factory StockRecord.fromJson(Map<String, Object?> j) => StockRecord(
    j['s']! as String,
    parseDay(j['d']! as String),
    (j['r'] as num?)?.toDouble(),
  );
}

class Lot {
  const Lot({
    required this.id,
    required this.supplyId,
    required this.purchasedOn,
    required this.quantity,
    required this.cost,
    required this.expiresOn,
  });

  final String id;
  final String supplyId;
  final DateTime purchasedOn;
  final double quantity;
  final double cost;
  final DateTime expiresOn;

  double get unitPrice => cost / quantity;

  Map<String, Object?> toJson() => {
    'id': id,
    's': supplyId,
    'p': dayKey(purchasedOn),
    'q': quantity,
    'c': cost,
    'e': dayKey(expiresOn),
  };

  factory Lot.fromJson(Map<String, Object?> j) => Lot(
    id: j['id']! as String,
    supplyId: j['s']! as String,
    purchasedOn: parseDay(j['p']! as String),
    quantity: (j['q']! as num).toDouble(),
    cost: (j['c']! as num).toDouble(),
    expiresOn: parseDay(j['e']! as String),
  );
}

class KiloData {
  KiloData({
    required this.categories,
    required this.supplies,
    required this.stock,
    required this.lots,
    Map<String, Set<String>>? boughtByDay,
  }) : boughtByDay = boughtByDay ?? {};

  final List<CategoryInfo> categories;
  final List<SupplyInfo> supplies;
  final List<StockRecord> stock;
  final List<Lot> lots;
  final Map<String, Set<String>> boughtByDay;

  SupplyInfo supply(String id) => supplies.firstWhere((s) => s.id == id);

  CategoryInfo category(String id) => categories.firstWhere((c) => c.id == id);

  Map<String, Object?> toJson() => {
    'categories': [for (final c in categories) c.toJson()],
    'supplies': [for (final s in supplies) s.toJson()],
    'stock': [for (final r in stock) r.toJson()],
    'lots': [for (final l in lots) l.toJson()],
    'bought': {for (final e in boughtByDay.entries) e.key: e.value.toList()},
  };

  factory KiloData.fromJson(Map<String, Object?> j) => KiloData(
    categories: [
      for (final c in j['categories']! as List)
        CategoryInfo.fromJson(c as Map<String, Object?>),
    ],
    supplies: [
      for (final s in j['supplies']! as List)
        SupplyInfo.fromJson(s as Map<String, Object?>),
    ],
    stock: [
      for (final r in j['stock']! as List)
        StockRecord.fromJson(r as Map<String, Object?>),
    ],
    lots: [
      for (final l in j['lots']! as List)
        Lot.fromJson(l as Map<String, Object?>),
    ],
    boughtByDay: {
      for (final e in (j['bought']! as Map<String, Object?>).entries)
        e.key: {for (final v in e.value! as List) v as String},
    },
  );
}
