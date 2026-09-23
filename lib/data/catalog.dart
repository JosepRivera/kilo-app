class Lot {
  const Lot(this.label, this.quantity, this.daysToExpiry);

  final String label;
  final double quantity;
  final int daysToExpiry;
}

class CatalogSupply {
  const CatalogSupply({
    required this.name,
    required this.unit,
    required this.onHand,
    required this.realDays,
    required this.weekForecast,
    this.icon,
    this.critical = true,
    this.lots = const [],
    this.phrases = const {},
  });

  final String name;
  final String unit;
  final double onHand;
  final int realDays;
  final List<double> weekForecast;
  final String? icon;
  final bool critical;
  final List<Lot> lots;
  final Map<String, double> phrases;

  bool get isLearning => realDays < coldStartDays;
}

class Category {
  const Category(this.name, this.supplies);

  final String name;
  final List<CatalogSupply> supplies;
}

const coldStartDays = 28;

const weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

const demoCatalog = [
  Category('Proteínas', [
    CatalogSupply(
      name: 'Pollo entero',
      unit: 'kg',
      icon: 'chicken',
      onHand: 12,
      realDays: 64,
      weekForecast: [8, 7.5, 8.5, 9, 13, 14, 6],
      lots: [Lot('del lunes', 8, 1), Lot('del jueves', 4, 3)],
      phrases: {'una jaba': 18},
    ),
    CatalogSupply(
      name: 'Carne de res',
      unit: 'kg',
      icon: 'beef',
      onHand: 5,
      realDays: 41,
      weekForecast: [2.5, 2, 2.5, 3, 4, 4.5, 2],
      lots: [Lot('del miércoles', 5, 4)],
    ),
    CatalogSupply(
      name: 'Pescado',
      unit: 'kg',
      icon: 'fish',
      onHand: 3,
      realDays: 12,
      weekForecast: [1.5, 1.5, 2, 2, 3, 3.5, 1],
      lots: [Lot('de ayer', 3, 2)],
    ),
  ]),
  Category('Verduras y frutas', [
    CatalogSupply(
      name: 'Papa canchán',
      unit: 'kg',
      icon: 'potato',
      onHand: 6,
      realDays: 64,
      weekForecast: [5, 5, 5.5, 6, 8, 9, 4],
      phrases: {'un saco': 50},
    ),
    CatalogSupply(
      name: 'Cebolla roja',
      unit: 'kg',
      icon: 'onion',
      onHand: 3,
      realDays: 52,
      weekForecast: [3, 3, 3, 3.5, 4.5, 5, 2.5],
    ),
    CatalogSupply(
      name: 'Tomate',
      unit: 'kg',
      icon: 'tomato',
      onHand: 4,
      realDays: 33,
      weekForecast: [2, 2, 2, 2.5, 3, 3.5, 1.5],
      phrases: {'medio balde': 5},
    ),
    CatalogSupply(
      name: 'Limón sutil',
      unit: 'kg',
      icon: 'lime',
      onHand: 1.5,
      realDays: 40,
      weekForecast: [1.5, 1.5, 2, 2, 3, 3, 1],
    ),
    CatalogSupply(
      name: 'Culantro',
      unit: 'atados',
      icon: 'cilantro',
      onHand: 1,
      realDays: 9,
      weekForecast: [1, 1, 1, 1, 2, 2, 1],
    ),
    CatalogSupply(
      name: 'Ají amarillo',
      unit: 'kg',
      icon: 'chili',
      onHand: 0.5,
      realDays: 17,
      weekForecast: [0.5, 0.5, 0.5, 0.5, 1, 1, 0.5],
    ),
    CatalogSupply(
      name: 'Choclo',
      unit: 'unidades',
      icon: 'corn',
      onHand: 20,
      realDays: 6,
      weekForecast: [6, 6, 6, 7, 10, 12, 5],
    ),
  ]),
  Category('Granos y abarrotes', [
    CatalogSupply(
      name: 'Arroz',
      unit: 'kg',
      icon: 'rice',
      onHand: 40,
      realDays: 64,
      critical: false,
      weekForecast: [4, 4, 4, 4.5, 6, 6.5, 3],
    ),
    CatalogSupply(
      name: 'Aceite vegetal',
      unit: 'litros',
      icon: 'oil',
      onHand: 18,
      realDays: 64,
      critical: false,
      weekForecast: [1.5, 1.5, 1.5, 2, 2.5, 3, 1],
      phrases: {'una lata': 18},
    ),
    CatalogSupply(
      name: 'Menestras',
      unit: 'kg',
      onHand: 6,
      realDays: 20,
      critical: false,
      weekForecast: [0.8, 0.8, 1, 1, 1.2, 1.2, 0.5],
    ),
  ]),
  Category('Condimentos y especias', [
    CatalogSupply(
      name: 'Sal',
      unit: 'kg',
      icon: 'salt',
      onHand: 5,
      realDays: 64,
      critical: false,
      weekForecast: [0.2, 0.2, 0.2, 0.2, 0.3, 0.3, 0.1],
    ),
    CatalogSupply(
      name: 'Ajo',
      unit: 'kg',
      icon: 'garlic',
      onHand: 2,
      realDays: 50,
      critical: false,
      weekForecast: [0.3, 0.3, 0.3, 0.3, 0.4, 0.5, 0.2],
    ),
  ]),
  Category('Lácteos y huevos', [
    CatalogSupply(
      name: 'Huevos',
      unit: 'unidades',
      icon: 'egg',
      onHand: 60,
      realDays: 38,
      weekForecast: [20, 20, 22, 22, 30, 34, 15],
    ),
    CatalogSupply(
      name: 'Queso fresco',
      unit: 'kg',
      icon: 'cheese',
      onHand: 1,
      realDays: 22,
      weekForecast: [0.4, 0.4, 0.5, 0.5, 0.7, 0.8, 0.3],
    ),
  ]),
];
