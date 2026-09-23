import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../data/store.dart';
import '../../theme/forecast_palette.dart';
import '../../ui/format.dart';
import '../../ui/panel.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = KiloScope.of(context);
    final e = store.engine;
    final p = ForecastPalette.of(context);
    final byMonth = e.monthlyWaste();
    final thisMonth = DateTime(store.today.year, store.today.month);
    final months = [
      for (var k = 3; k >= 0; k--)
        DateTime(thisMonth.year, thisMonth.month - k),
    ];
    final now = byMonth[thisMonth] ?? 0;
    final before = byMonth[months[2]];
    final perSupply = <String, (double, double)>{};
    for (final w in e.waste().where(
      (w) => w.date.year == thisMonth.year && w.date.month == thisMonth.month,
    )) {
      final prev = perSupply[w.supplyId] ?? (0, 0);
      perSupply[w.supplyId] = (prev.$1 + w.soles, prev.$2 + w.quantity);
    }
    final top = perSupply.entries.toList()
      ..sort((a, b) => b.value.$1.compareTo(a.value.$1));

    return ForecastPage(
      title: 'Ahorro',
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Este mes perdiste',
                style: TextStyle(fontSize: 15, color: p.muted),
              ),
              Text(
                soles(now),
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w300,
                  height: 1.1,
                  color: p.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              if (before == null)
                Text(
                  'Aún no hay mes anterior para comparar.',
                  style: TextStyle(fontSize: 15, color: p.muted),
                )
              else
                _Change(diff: before - now),
            ],
          ),
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelHeader(
                CupertinoIcons.chart_bar_alt_fill,
                'PERDIDO POR MES',
              ),
              _MonthBars(
                months: months,
                values: [for (final m in months) byMonth[m] ?? 0],
              ),
            ],
          ),
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelHeader(
                CupertinoIcons.trash,
                'LO QUE MÁS SE VENCIÓ ESTE MES',
              ),
              if (top.isEmpty)
                Text(
                  'Nada se venció este mes.',
                  style: TextStyle(fontSize: 17, color: p.muted),
                ),
              for (final (i, t) in top.take(5).indexed) ...[
                if (i > 0) const PanelDivider(),
                Builder(
                  builder: (context) {
                    final s = store.data.supply(t.key);
                    return SizedBox(
                      height: 56,
                      child: Row(
                        children: [
                          supplyIcon(s.icon, 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.name,
                                  style: TextStyle(fontSize: 17, color: p.text),
                                ),
                                Text(
                                  '${withUnit(double.parse(t.value.$2.toStringAsFixed(1)), s.unit)} vencidos',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: p.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            soles(t.value.$1),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: p.text,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(CupertinoIcons.lock_fill, size: 14, color: p.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Solo lo ve el dueño. Es lo que pagaste por insumos que se vencieron; no es tu ganancia.',
                  style: TextStyle(fontSize: 13, color: p.muted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Change extends StatelessWidget {
  const _Change({required this.diff});

  final double diff;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final better = diff >= 0;
    final color = better ? p.good : p.alert;
    return Row(
      children: [
        Icon(
          better
              ? CupertinoIcons.arrow_down_circle_fill
              : CupertinoIcons.arrow_up_circle_fill,
          size: 20,
          color: color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${soles(diff.abs())} ${better ? 'menos' : 'más'} que el mes pasado',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthBars extends StatelessWidget {
  const _MonthBars({required this.months, required this.values});

  final List<DateTime> months;
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final top = math.max(values.reduce(math.max), 1.0);
    return SizedBox(
      height: 168,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (i, m) in months.indexed)
            Expanded(
              child: Semantics(
                label: '${monthShort[m.month - 1]}: ${soles(values[i])}',
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        soles(values[i]),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: i == months.length - 1 ? p.text : p.muted,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 36,
                        height: math.max(4, 110 * values[i] / top),
                        decoration: BoxDecoration(
                          color: i == months.length - 1
                              ? p.accent
                              : p.accent.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        monthShort[m.month - 1],
                        style: TextStyle(fontSize: 13, color: p.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
