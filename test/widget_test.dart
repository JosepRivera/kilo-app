import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilo_app/app.dart';
import 'package:kilo_app/data/supplies.dart';
import 'package:kilo_app/features/dictation/dictation_sheet.dart';
import 'package:kilo_app/features/today/today_screen.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const KiloApp());
    await tester.pumpAndSettle();
  }

  testWidgets('starts on Today without overflow', (tester) async {
    await pumpApp(tester);
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.text('Compra de hoy'), findsOneWidget);
  });

  testWidgets('tapping a supply marks it as bought', (tester) async {
    await pumpApp(tester);
    expect(find.byIcon(CupertinoIcons.checkmark_alt), findsNothing);
    await tester.tap(find.text('Pollo entero'));
    await tester.pumpAndSettle();
    expect(find.byIcon(CupertinoIcons.checkmark_alt), findsOneWidget);
  });

  testWidgets('tabs switch between places', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Insumos').last);
    await tester.pumpAndSettle();
    expect(find.text('Compra de hoy'), findsNothing);
  });

  testWidgets('mic opens the dictation sheet', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(CupertinoIcons.mic_fill));
    await tester.pumpAndSettle();
    expect(find.text('Te escucho'), findsOneWidget);
    await tester.tap(find.text('Compra'));
    await tester.pumpAndSettle();
    expect(find.text('Qué compraste, cuánto y a cuánto'), findsOneWidget);
  });

  testWidgets('supplies without their own art fall back to the generic icon', (
    tester,
  ) async {
    await tester.pumpWidget(Center(child: supplyIcon('does-not-exist', 36)));
    await tester.pumpAndSettle();
    final shown = tester
        .widgetList<Image>(find.byType(Image))
        .map((i) => (i.image as AssetImage).assetName);
    expect(shown, contains('assets/supplies/generic.png'));
  });

  testWidgets('supply detail shows the week and the expiring lot', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Insumos').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pollo entero'));
    await tester.pumpAndSettle();
    expect(find.text('Se usa más el viernes y el sábado.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('vence mañana'), 200);
    expect(find.text('vence mañana'), findsOneWidget);
  });

  testWidgets('supply search filters the catalog', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Insumos').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CupertinoSearchTextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No hay insumos con “zzz”.'), findsOneWidget);
  });

  testWidgets('savings compares this month against the previous one', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Ahorro').last);
    await tester.pumpAndSettle();
    expect(find.text('S/ 50 menos que el mes pasado'), findsOneWidget);
  });

  test(
    'dictation opens on the stock close at night and on purchase by day',
    () {
      expect(actionForTime(DateTime(2026, 9, 23, 22)), VoiceAction.stockClose);
      expect(actionForTime(DateTime(2026, 9, 24, 2)), VoiceAction.stockClose);
      expect(actionForTime(DateTime(2026, 9, 24, 9)), VoiceAction.purchase);
    },
  );

  Future<void> dictate(WidgetTester tester, String segment) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(CupertinoIcons.mic_fill));
    await tester.pumpAndSettle();
    await tester.tap(find.text(segment));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
  }

  testWidgets('stock close review saves only after every check is answered', (
    tester,
  ) async {
    await dictate(tester, 'Cierre de hoy');
    expect(find.text('Revisar'), findsNWidgets(2));
    await tester.tap(find.text('Sí, es correcto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar 3 kg'));
    await tester.pumpAndSettle();
    expect(find.text('Papa corregida a 3 kg'), findsOneWidget);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Compra de hoy'), findsOneWidget);
  });

  testWidgets('purchase review resolves the ambiguous supply', (tester) async {
    await dictate(tester, 'Compra');
    await tester.tap(find.text('Limón sutil'));
    await tester.pumpAndSettle();
    expect(find.text('Limón: Limón sutil'), findsOneWidget);
    expect(find.text('LOTES QUE SE CREAN'), findsOneWidget);
  });
}
