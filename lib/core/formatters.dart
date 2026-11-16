import 'package:intl/intl.dart';

const _locale = 'es_419';
const _feminineUnits = {'unidades', 'docenas'};

final _quantityFormat = NumberFormat('#,##0.#', _locale);
final _solesFormat = NumberFormat('#,##0', _locale);
final _moneyFormat = NumberFormat('#,##0.00', _locale);

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
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

const monthLong = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

bool isCountUnit(String unit) => unit != 'kg' && unit != 'litros';

String formatQuantity(double value) => _quantityFormat.format(value);

String unitLabel(String unit, double amount) {
  final isOne = (amount * 10).round() == 10;
  if (!isOne || !unit.endsWith('s')) return unit;
  final singular = unit.substring(0, unit.length - 1);
  return singular == 'unidade' ? 'unidad' : singular;
}

String withUnit(double value, String unit) {
  final shown = isCountUnit(unit) ? value.roundToDouble() : value;
  return '${formatQuantity(shown)} ${unitLabel(unit, shown)}';
}

String soles(double value) => 'S/${_solesFormat.format(value)}';

String money(double value) => 'S/${_moneyFormat.format(value)}';

String shortDate(DateTime day) => '${day.day} ${monthShort[day.month - 1]}';

String longDate(DateTime day) {
  final weekday = weekdayLong[day.weekday - 1];
  return '$weekday ${day.day} de ${monthLong[day.month - 1]}';
}

String weekdayAndDay(DateTime day) =>
    '${capitalize(weekdayLong[day.weekday - 1])} ${day.day}';

String monthLabel(String month) =>
    monthShort[int.parse(month.substring(5, 7)) - 1];

String expiryText(int days) => switch (days) {
  < 0 => 'venció',
  0 => 'vence hoy',
  1 => 'vence mañana',
  _ => 'vence en $days días',
};

String lotLabel(DateTime purchasedOn, DateTime today) =>
    switch (today.difference(purchasedOn).inDays) {
      0 => 'de hoy',
      1 => 'de ayer',
      _ => 'del ${weekdayLong[purchasedOn.weekday - 1]}',
    };

String capitalize(String text) =>
    text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';

String howMany(String unit) =>
    _feminineUnits.contains(unit) ? '¿Cuántas $unit' : '¿Cuántos $unit';

double? parseAmount(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

String editableAmount(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
