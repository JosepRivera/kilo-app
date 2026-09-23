import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilo_app/app.dart';
import 'package:kilo_app/data/store.dart';
import 'package:kilo_app/features/today/today_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late KiloStore store;
  final today = DateTime(2026, 9, 23);

  Future<void> pumpApp(WidgetTester tester, {int hour = 9}) async {
    SharedPreferences.setMockInitialValues({});
    store = await KiloStore.load(clock: () => DateTime(2026, 9, 23, hour));
    await tester.pumpWidget(KiloApp(store: store));
    await tester.pumpAndSettle();
  }

  List<String> toBuyNames() => [
    for (final s in store.data.supplies)
      if (store.engine.isDue(s.categoryId) &&
          store.engine.recommend(s.id).toBuy > 0)
        s.name,
  ];

  Future<void> dictate(WidgetTester tester, String segment) async {
    await tester.tap(find.byIcon(CupertinoIcons.mic_fill));
    await tester.pumpAndSettle();
    await tester.tap(find.text(segment));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
  }

  Future<void> confirmAllAndSave(WidgetTester tester) async {
    while (find.text('Sí, es correcto').evaluate().isNotEmpty) {
      await tester.tap(find.text('Sí, es correcto').first);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
  }

  testWidgets('starts on Today with a purchase list and no overflow', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(toBuyNames(), isNotEmpty);
  });

  testWidgets('checking off a supply persists across reloads', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text(toBuyNames().first).first);
    await tester.pumpAndSettle();
    final reloaded = await KiloStore.load(
      clock: () => DateTime(2026, 9, 23, 9),
    );
    expect(reloaded.data.boughtByDay['2026-09-23'], isNotEmpty);
  });

  testWidgets('saving the stock close records today', (tester) async {
    await pumpApp(tester, hour: 21);
    await dictate(tester, 'Cierre de hoy');
    await confirmAllAndSave(tester);
    expect(store.data.stock.where((r) => r.date == today), isNotEmpty);
  });

  testWidgets('saving a purchase creates lots and shrinks the list', (
    tester,
  ) async {
    await pumpApp(tester);
    final before = toBuyNames().length;
    await dictate(tester, 'Compra');
    await confirmAllAndSave(tester);
    expect(store.data.lots.where((l) => l.purchasedOn == today), isNotEmpty);
    expect(toBuyNames().length, lessThan(before));
  });
}
