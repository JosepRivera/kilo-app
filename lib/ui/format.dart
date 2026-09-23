import 'package:flutter/widgets.dart';

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

bool isCountUnit(String unit) => unit != 'kg' && unit != 'litros';

String withUnit(double v, String unit) {
  final shown = isCountUnit(unit) ? v.roundToDouble() : v;
  final u = shown != 1
      ? unit
      : unit.endsWith('des')
      ? unit.substring(0, unit.length - 2)
      : unit.endsWith('s')
      ? unit.substring(0, unit.length - 1)
      : unit;
  return '${formatQty(shown)} $u';
}

String soles(double v) => 'S/ ${v.round()}';

String money(double v) => 'S/ ${v.toStringAsFixed(2)}';

const weekdayShort = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

const weekdayLong = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

const monthShort = [
  'Ene',
  'Feb',
  'Mar',
  'Abr',
  'May',
  'Jun',
  'Jul',
  'Ago',
  'Set',
  'Oct',
  'Nov',
  'Dic',
];

String expiryText(int days) => switch (days) {
  < 0 => 'vencido',
  0 => 'vence hoy',
  1 => 'vence mañana',
  _ => 'vence en $days días',
};
