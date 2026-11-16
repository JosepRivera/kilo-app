import 'package:flutter_test/flutter_test.dart';
import 'package:kilo_app/core/formatters.dart';

void main() {
  group('withUnit', () {
    test('keeps one decimal for weight and volume', () {
      expect(withUnit(2.5, 'kg'), '2.5 kg');
      expect(withUnit(1500, 'kg'), '1,500 kg');
      expect(withUnit(3, 'litros'), '3 litros');
    });

    test('rounds count units and singularizes one', () {
      expect(withUnit(2.6, 'unidades'), '3 unidades');
      expect(withUnit(1, 'unidades'), '1 unidad');
      expect(withUnit(1, 'atados'), '1 atado');
      expect(withUnit(1, 'litros'), '1 litro');
      expect(withUnit(1, 'kg'), '1 kg');
    });
  });

  test('soles has no decimals and money has two', () {
    expect(soles(1234.4), 'S/1,234');
    expect(money(9.5), 'S/9.50');
  });

  test('expiryText reads like the Swift app', () {
    expect(expiryText(-1), 'venció');
    expect(expiryText(0), 'vence hoy');
    expect(expiryText(1), 'vence mañana');
    expect(expiryText(4), 'vence en 4 días');
  });

  test('lotLabel names the purchase day', () {
    final today = DateTime.utc(2026, 11, 16);
    expect(lotLabel(today, today), 'de hoy');
    expect(lotLabel(DateTime.utc(2026, 11, 15), today), 'de ayer');
    expect(lotLabel(DateTime.utc(2026, 11, 13), today), 'del viernes');
  });

  test('dates and months are Spanish', () {
    final day = DateTime.utc(2026, 11, 16);
    expect(longDate(day), 'lunes 16 de noviembre');
    expect(shortDate(day), '16 nov');
    expect(weekdayAndDay(day), 'Lunes 16');
    expect(monthLabel('2026-08'), 'ago');
  });

  test('howMany agrees with the unit gender', () {
    expect(howMany('kg'), '¿Cuántos kg');
    expect(howMany('unidades'), '¿Cuántas unidades');
  });

  test('parseAmount accepts comma or dot decimals', () {
    expect(parseAmount('2,5'), 2.5);
    expect(parseAmount(' 3 '), 3);
    expect(parseAmount(''), isNull);
    expect(editableAmount(3), '3');
    expect(editableAmount(2.5), '2.5');
  });
}
