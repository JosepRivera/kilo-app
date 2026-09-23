import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../data/store.dart';
import '../../domain/engine.dart';
import '../../domain/models.dart';
import '../../theme/forecast_palette.dart';
import '../../ui/format.dart';
import '../../ui/faded_header.dart';
import '../../ui/panel.dart';

class SupplyDetailScreen extends StatelessWidget {
  const SupplyDetailScreen({super.key, required this.supplyId});

  final String supplyId;

  @override
  Widget build(BuildContext context) {
    final store = KiloScope.of(context);
    final e = store.engine;
    final p = ForecastPalette.of(context);
    final s = store.data.supply(supplyId);
    final lots = e
        .activeLots(s.id)
        .where((l) => !l.lot.id.startsWith(openingLotPrefix))
        .toList();

    return FadedHeaderScaffold(
      title: s.name,
      largeTitle: false,
      leading: CupertinoNavigationBarBackButton(
        previousPageTitle: 'Insumos',
        color: p.accent,
      ),
      children: [
        _Now(
          supply: s,
          onHand: e.currentStock(s.id),
          realDays: e.realDays(s.id),
        ),
        const SizedBox(height: 12),
        _Week(supply: s, engine: e, from: store.today),
        if (lots.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Lots(supply: s, lots: lots, engine: e, today: store.today),
        ],
        const SizedBox(height: 12),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelHeader(CupertinoIcons.mic, 'CÓMO SE REGISTRA'),
              SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<bool>(
                  groupValue: s.critical,
                  onValueChanged: (v) => store.setCritical(s.id, v!),
                  children: const {
                    true: Text('Cada noche'),
                    false: Text('Cada semana'),
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.critical
                    ? 'Lo dictas en el cierre de cada noche. Ideal para insumos caros o que se malogran.'
                    : 'Lo dictas una vez por semana. Ideal para insumos baratos que duran.',
                style: TextStyle(fontSize: 13, color: p.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelHeader(CupertinoIcons.scope, 'UNIDAD'),
              _Line(label: 'Se mide en', value: s.unit),
              for (final e in s.phrases.entries) ...[
                const PanelDivider(),
                _Line(label: '“${e.key}”', value: withUnit(e.value, s.unit)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Now extends StatelessWidget {
  const _Now({
    required this.supply,
    required this.onHand,
    required this.realDays,
  });

  final SupplyInfo supply;
  final double onHand;
  final int realDays;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final learning = realDays < coldStartDays;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quedan',
                      style: TextStyle(fontSize: 15, color: p.muted),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          formatQty(
                            isCountUnit(supply.unit)
                                ? onHand.roundToDouble()
                                : onHand,
                          ),
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.w300,
                            height: 1.1,
                            color: p.text,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          supply.unit,
                          style: TextStyle(fontSize: 22, color: p.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              supplyIcon(supply.icon, 72),
            ],
          ),
          if (learning) ...[
            const SizedBox(height: 12),
            Text(
              'Kilo aún aprende este insumo · $realDays de $coldStartDays días',
              style: TextStyle(fontSize: 13, color: p.muted),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: [
                    Expanded(
                      flex: realDays,
                      child: ColoredBox(color: p.accent),
                    ),
                    Expanded(
                      flex: coldStartDays - realDays,
                      child: ColoredBox(color: p.track),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Week extends StatelessWidget {
  const _Week({required this.supply, required this.engine, required this.from});

  final SupplyInfo supply;
  final Engine engine;
  final DateTime from;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final days = [
      for (var k = 0; k < 7; k++) DateTime(from.year, from.month, from.day + k),
    ];
    final w = [for (final d in days) engine.forecast(supply.id, d)];
    final top = math.max(w.reduce(math.max), 0.001);
    final busiest =
        ([
            for (var i = 0; i < 7; i++) i,
          ]..sort((a, b) => w[b].compareTo(w[a]))).take(2).toList()
          ..sort((a, b) => days[a].weekday.compareTo(days[b].weekday));

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelHeader(
            CupertinoIcons.calendar,
            'USO ESPERADO · PRÓXIMOS 7 DÍAS',
          ),
          Text(
            'Se usa más el ${weekdayLong[days[busiest[0]].weekday - 1]} y el ${weekdayLong[days[busiest[1]].weekday - 1]}.',
            style: TextStyle(fontSize: 15, color: p.text),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < 7; i++) ...[
            const PanelDivider(),
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      i == 0 ? 'Hoy' : weekdayShort[days[i].weekday - 1],
                      style: TextStyle(fontSize: 17, color: p.text),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: w[i] / top,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: busiest.contains(i)
                                ? p.accent
                                : p.accent.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 104,
                    child: Text(
                      withUnit(
                        double.parse(w[i].toStringAsFixed(1)),
                        supply.unit,
                      ),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 17,
                        color: p.text,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Lots extends StatelessWidget {
  const _Lots({
    required this.supply,
    required this.lots,
    required this.engine,
    required this.today,
  });

  final SupplyInfo supply;
  final List<LotState> lots;
  final Engine engine;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelHeader(CupertinoIcons.cube_box, 'LOTES'),
          for (final (i, l) in lots.indexed) ...[
            if (i > 0) const PanelDivider(),
            Builder(
              builder: (context) {
                final days = l.lot.expiresOn.difference(today).inDays;
                final urgent = days <= 1;
                return SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Lote ${engine.lotLabel(l.lot)}',
                          style: TextStyle(fontSize: 17, color: p.text),
                        ),
                      ),
                      Text(
                        withUnit(
                          double.parse(l.remaining.toStringAsFixed(1)),
                          supply.unit,
                        ),
                        style: TextStyle(
                          fontSize: 17,
                          color: p.muted,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 116,
                        child: Text(
                          expiryText(days),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: urgent
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: urgent ? p.alert : p.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label, value;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 17, color: p.text)),
          ),
          Text(value, style: TextStyle(fontSize: 17, color: p.muted)),
        ],
      ),
    );
  }
}
