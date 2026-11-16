import '../json.dart';
import 'close_check.dart';
import 'price_check.dart';

class Supply {
  const Supply({
    required this.id,
    required this.name,
    required this.unit,
    required this.categoryId,
    required this.icon,
    required this.critical,
    required this.shelfLifeDays,
    required this.referencePrice,
    required this.phrases,
    required this.stock,
    required this.realDays,
    required this.learning,
    required this.expiresInDays,
    required this.dueForClose,
    required this.expectedRemaining,
    required this.closeCheck,
    required this.priceCheck,
  });

  factory Supply.fromJson(Json json) {
    final closeCheck = json['closeCheck'] as Json?;
    final priceCheck = json['priceCheck'] as Json?;
    return Supply(
      id: json['id']! as String,
      name: json['name']! as String,
      unit: json['unit']! as String,
      categoryId: json['categoryId']! as String,
      icon: json['icon'] as String?,
      critical: json['critical']! as bool,
      shelfLifeDays: decodeInt(json['shelfLifeDays']),
      referencePrice: decodeDouble(json['referencePrice']),
      phrases: {
        for (final MapEntry(:key, :value) in (json['phrases']! as Json).entries)
          key: decodeDouble(value),
      },
      stock: decodeDouble(json['stock']),
      realDays: decodeInt(json['realDays']),
      learning: json['learning']! as bool,
      expiresInDays: (json['expiresInDays'] as num?)?.toInt(),
      dueForClose: json['dueForClose']! as bool,
      expectedRemaining: decodeDouble(json['expectedRemaining']),
      closeCheck: closeCheck == null ? null : CloseCheck.fromJson(closeCheck),
      priceCheck: priceCheck == null ? null : PriceCheck.fromJson(priceCheck),
    );
  }

  static const learningDays = 28;

  final String id;
  final String name;
  final String unit;
  final String categoryId;
  final String? icon;
  final bool critical;
  final int shelfLifeDays;
  final double referencePrice;
  final Map<String, double> phrases;
  final double stock;
  final int realDays;
  final bool learning;
  final int? expiresInDays;
  final bool dueForClose;
  final double expectedRemaining;
  final CloseCheck? closeCheck;
  final PriceCheck? priceCheck;
}
