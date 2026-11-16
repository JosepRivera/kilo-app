import '../../data/models/supply.dart';
import '../../data/models/supply_category.dart';
import 'supply_section.dart';

class SupplySections {
  const SupplySections();

  static const _plain = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };

  List<SupplySection> group(
    List<Supply> supplies,
    List<SupplyCategory> categories,
    String query,
  ) {
    final needle = fold(query.trim());
    final matches = [
      for (final supply in supplies)
        if (fold(supply.name).contains(needle)) supply,
    ]..sort((a, b) => fold(a.name).compareTo(fold(b.name)));
    return [
      for (final category in categories)
        if (matches.where((s) => s.categoryId == category.id).toList()
            case final inCategory when inCategory.isNotEmpty)
          SupplySection(title: category.name, supplies: inCategory),
    ];
  }

  List<Supply> expiring(List<Supply> supplies) => [
    for (final supply in supplies)
      if (supply.expiresInDays != null) supply,
  ]..sort((a, b) => a.expiresInDays!.compareTo(b.expiresInDays!));

  String fold(String text) =>
      text.toLowerCase().split('').map((char) => _plain[char] ?? char).join();
}
