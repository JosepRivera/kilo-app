import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../data/catalog.dart';
import '../../data/supplies.dart';
import '../../theme/forecast_palette.dart';
import '../../ui/panel.dart';

class SupplyDetailScreen extends StatefulWidget {
  const SupplyDetailScreen({super.key, required this.supply});

  final CatalogSupply supply;

  @override
  State<SupplyDetailScreen> createState() => _SupplyDetailScreenState();
}

class _SupplyDetailScreenState extends State<SupplyDetailScreen> {
  late var _critical = widget.supply.critical;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final s = widget.supply;

    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(s.name),
        previousPageTitle: 'Insumos',
        backgroundColor: p.background.withValues(alpha: 0.9),
        border: null,
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            _Now(supply: s),
            const SizedBox(height: 12),
            _Week(supply: s),
            if (s.lots.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Lots(supply: s),
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
                      groupValue: _critical,
                      onValueChanged: (v) => setState(() => _critical = v!),
                      children: const {
                        true: Text('Cada noche'),
                        false: Text('Cada semana'),
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _critical
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
                    _Line(
                      label: '“${e.key}”',
                      value: '${formatQty(e.value)} ${s.unit}',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Now extends StatelessWidget {
  const _Now({required this.supply});

  final CatalogSupply supply;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final s = supply;
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
                          formatQty(s.onHand),
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
                          s.unit,
                          style: TextStyle(fontSize: 22, color: p.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              supplyIcon(s.icon, 72),
            ],
          ),
          if (s.isLearning) ...[
            const SizedBox(height: 12),
            Text(
              'Kilo aún aprende este insumo · ${s.realDays} de $coldStartDays días',
              style: TextStyle(fontSize: 13, color: p.muted),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 6,
                child: LinearProgress(
                  value: s.realDays / coldStartDays,
                  color: p.accent,
                  track: p.track,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LinearProgress extends StatelessWidget {
  const LinearProgress({
    super.key,
    required this.value,
    required this.color,
    required this.track,
  });

  final double value;
  final Color color, track;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        flex: (value * 1000).round(),
        child: ColoredBox(color: color),
      ),
      Expanded(
        flex: 1000 - (value * 1000).round(),
        child: ColoredBox(color: track),
      ),
    ],
  );
}

class _Week extends StatelessWidget {
  const _Week({required this.supply});

  final CatalogSupply supply;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final w = supply.weekForecast;
    final top = w.reduce(math.max);
    final busiest = ([
      for (var i = 0; i < 7; i++) i,
    ]..sort((a, b) => w[b].compareTo(w[a]))).take(2).toList()..sort();

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelHeader(
            CupertinoIcons.calendar,
            'USO ESPERADO · PRÓXIMOS 7 DÍAS',
          ),
          Text(
            'Se usa más el ${_dayName(busiest[0])} y el ${_dayName(busiest[1])}.',
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
                    width: 44,
                    child: Text(
                      weekdays[i],
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
                    width: 96,
                    child: Text(
                      '${formatQty(w[i])} ${supply.unit}',
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

String _dayName(int i) => const [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
][i];

class _Lots extends StatelessWidget {
  const _Lots({required this.supply});

  final CatalogSupply supply;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelHeader(CupertinoIcons.cube_box, 'LOTES'),
          for (final (i, l) in supply.lots.indexed) ...[
            if (i > 0) const PanelDivider(),
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Lote ${l.label}',
                      style: TextStyle(fontSize: 17, color: p.text),
                    ),
                  ),
                  Text(
                    '${formatQty(l.quantity)} ${supply.unit}',
                    style: TextStyle(
                      fontSize: 17,
                      color: p.muted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 108,
                    child: Text(
                      _expiry(l.daysToExpiry),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: l.daysToExpiry <= 1
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: l.daysToExpiry <= 1 ? p.alert : p.muted,
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

String _expiry(int days) => switch (days) {
  <= 0 => 'vence hoy',
  1 => 'vence mañana',
  _ => 'vence en $days días',
};

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
