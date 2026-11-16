import '../../data/models/supply.dart';

class SupplySection {
  const SupplySection({required this.title, required this.supplies});

  final String title;
  final List<Supply> supplies;
}
