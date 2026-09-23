import 'package:flutter_test/flutter_test.dart';
import 'package:kilo_app/domain/engine.dart';
import 'package:kilo_app/domain/seed.dart';

void main() {
  final today = DateTime(2026, 9, 23);
  final data = seedData(today);
  final engine = Engine(data, today);

  test('seed is deterministic', () {
    expect(seedData(today).toJson(), data.toJson());
  });

  test('seed history feeds the cycle', () {
    expect(engine.realDays('chicken'), greaterThanOrEqualTo(28));
    expect(engine.isLearning('cilantro'), isTrue);
    expect(engine.isLearning('chicken'), isFalse);
    expect(engine.consumption('rice').values.any((c) => c.estimated), isTrue);
    expect(engine.consumption('chicken').values.any((c) => c.closed), isTrue);
    expect(engine.waste(), isNotEmpty);
    for (final s in data.supplies) {
      expect(engine.forecast(s.id, today), greaterThan(0), reason: s.id);
      expect(engine.currentStock(s.id), greaterThanOrEqualTo(0), reason: s.id);
    }
  });

  test('lots stay reconciled with the recorded stock', () {
    for (final s in data.supplies) {
      final lots = engine.activeLots(s.id).fold(0.0, (t, l) => t + l.remaining);
      expect(lots, closeTo(engine.currentStock(s.id), 0.05), reason: s.id);
    }
  });
}
