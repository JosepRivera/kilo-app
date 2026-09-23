import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../data/supplies.dart';
import '../../theme/forecast_palette.dart';
import '../../ui/panel.dart';

class MonthLoss {
  const MonthLoss(this.month, this.soles);

  final String month;
  final double soles;
}

class Waste {
  const Waste(this.name, this.icon, this.soles, this.quantity, this.unit);

  final String name;
  final String? icon;
  final double soles, quantity;
  final String unit;
}

const _months = [
  MonthLoss('Jun', 380),
  MonthLoss('Jul', 310),
  MonthLoss('Ago', 250),
  MonthLoss('Set', 200),
];
const _topWaste = [
  Waste('Pollo entero', 'chicken', 84, 7, 'kg'),
  Waste('Tomate', 'tomato', 38, 12, 'kg'),
  Waste('Culantro', 'cilantro', 22, 11, 'atados'),
  Waste('Queso fresco', 'cheese', 18, 1, 'kg'),
];

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final now = _months.last.soles;
    final diff = _months[_months.length - 2].soles - now;
    final better = diff >= 0;

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
              Row(
                children: [
                  Icon(
                    better
                        ? CupertinoIcons.arrow_down_circle_fill
                        : CupertinoIcons.arrow_up_circle_fill,
                    size: 20,
                    color: better ? p.good : p.alert,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${soles(diff.abs())} ${better ? 'menos' : 'más'} que el mes pasado',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: better ? p.good : p.alert,
                    ),
                  ),
                ],
              ),
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
              _MonthBars(months: _months),
            ],
          ),
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelHeader(CupertinoIcons.trash, 'LO QUE MÁS SE VENCIÓ'),
              for (final (i, w) in _topWaste.indexed) ...[
                if (i > 0) const PanelDivider(),
                SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      supplyIcon(w.icon, 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              w.name,
                              style: TextStyle(fontSize: 17, color: p.text),
                            ),
                            Text(
                              '${withUnit(w.quantity, w.unit)} vencidos',
                              style: TextStyle(fontSize: 13, color: p.muted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        soles(w.soles),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: p.text,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
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

String soles(double v) => 'S/ ${v.round()}';

class _MonthBars extends StatelessWidget {
  const _MonthBars({required this.months});

  final List<MonthLoss> months;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final top = months.map((m) => m.soles).reduce(math.max);
    return SizedBox(
      height: 168,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (i, m) in months.indexed)
            Expanded(
              child: Semantics(
                label: '${m.month}: ${soles(m.soles)}',
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        soles(m.soles),
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
                        height: 110 * m.soles / top,
                        decoration: BoxDecoration(
                          color: i == months.length - 1
                              ? p.accent
                              : p.accent.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        m.month,
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
