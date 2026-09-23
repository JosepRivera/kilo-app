import 'package:flutter/cupertino.dart';

class Supply {
  const Supply(
    this.name,
    this.unit, {
    required this.toBuy,
    required this.onHand,
    required this.realDays,
    this.icon,
    this.expiryAlert,
  });

  final String name;
  final String unit;
  final double toBuy;
  final double onHand;
  final int realDays;
  final String? expiryAlert;
  final String? icon;

  double get needed => toBuy + onHand;
  bool get isLearning => realDays < 28;
}

const demoShoppingList = [
  Supply(
    'Pollo entero',
    'kg',
    toBuy: 27,
    onHand: 12,
    realDays: 64,
    icon: 'chicken',
    expiryAlert: 'El lote del lunes vence mañana',
  ),
  Supply(
    'Papa canchán',
    'kg',
    toBuy: 18,
    onHand: 6,
    realDays: 64,
    icon: 'potato',
  ),
  Supply(
    'Cebolla roja',
    'kg',
    toBuy: 10,
    onHand: 3,
    realDays: 52,
    icon: 'onion',
  ),
  Supply(
    'Limón sutil',
    'kg',
    toBuy: 6,
    onHand: 1.5,
    realDays: 40,
    icon: 'lime',
  ),
  Supply(
    'Culantro',
    'atados',
    toBuy: 4,
    onHand: 1,
    realDays: 9,
    icon: 'cilantro',
  ),
  Supply(
    'Ají amarillo',
    'kg',
    toBuy: 2,
    onHand: 0.5,
    realDays: 17,
    icon: 'chili',
  ),
];
const demoCovered = {
  'Arroz': 'rice',
  'Aceite': 'oil',
  'Sal': 'salt',
  'Ajo': 'garlic',
};

Widget supplyIcon(String? icon, double size) => Image.asset(
  'assets/supplies/${icon ?? 'generic'}.png',
  width: size,
  height: size,
  excludeFromSemantics: true,
  errorBuilder: (_, _, _) => Image.asset(
    'assets/supplies/generic.png',
    width: size,
    height: size,
    excludeFromSemantics: true,
  ),
);

String formatQty(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
