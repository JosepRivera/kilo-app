import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../data/store.dart';
import '../../domain/engine.dart';
import '../../theme/forecast_palette.dart';
import '../../ui/format.dart';
import '../../ui/panel.dart';
import '../../ui/range_bar.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = KiloScope.of(context);
    final e = store.engine;
    final p = ForecastPalette.of(context);
    final due = store.data.categories
        .where((c) => e.isDue(c.id))
        .map((c) => c.id)
        .toSet();
    final recs = [
      for (final s in store.data.supplies)
        if (due.contains(s.categoryId)) e.recommend(s.id),
    ];
    final toBuy = recs.where((r) => r.toBuy > 0).toList();
    final covered = recs.where((r) => r.toBuy == 0).toList();

    return ForecastPage(
      title: 'Compra de hoy',
      children: [
        for (final a in e.expiryAlerts())
          _AlertPanel(alert: a, lotLabel: e.lotLabel(a.lot.lot)),
        if (toBuy.isEmpty)
          Panel(
            child: Row(
              children: [
                Icon(CupertinoIcons.sun_max_fill, color: p.accent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    due.isEmpty
                        ? 'Hoy no toca ir al mercado. Tu stock alcanza.'
                        : 'Ya tienes todo lo de hoy.',
                    style: TextStyle(fontSize: 17, color: p.text),
                  ),
                ),
              ],
            ),
          ),
        if (toBuy.isNotEmpty)
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelHeader(
                  CupertinoIcons.calendar,
                  'HASTA TU PRÓXIMA COMPRA',
                ),
                for (final r in toBuy) ...[
                  const PanelDivider(),
                  _SupplyRow(
                    rec: r,
                    learning: e.isLearning(r.supply.id),
                    bought: store.isBought(r.supply.id),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      store.toggleBought(r.supply.id);
                    },
                  ),
                ],
                const SizedBox(height: 8),
                const _Legend(),
              ],
            ),
          ),
        if (covered.isNotEmpty)
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelHeader(
                  CupertinoIcons.checkmark_seal_fill,
                  'YA ALCANZA',
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  children: [
                    for (final r in covered)
                      SizedBox(
                        width: 84,
                        child: Column(
                          children: [
                            supplyIcon(r.supply.icon, 36),
                            const SizedBox(height: 4),
                            Text(
                              r.supply.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: TextStyle(fontSize: 13, color: p.text),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AlertPanel extends StatelessWidget {
  const _AlertPanel({required this.alert, required this.lotLabel});

  final ExpiryAlert alert;
  final String lotLabel;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    return Panel(
      color: p.alertBackground,
      child: Row(
        children: [
          supplyIcon(alert.supply.icon, 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'El lote $lotLabel ${expiryText(alert.daysLeft)}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: p.alert,
                  ),
                ),
                Text(
                  '${alert.supply.name} · quedan ${withUnit(alert.lot.remaining, alert.supply.unit)} · úsalo primero',
                  style: TextStyle(fontSize: 15, color: p.alert),
                ),
              ],
            ),
          ),
          Icon(CupertinoIcons.exclamationmark_triangle_fill, color: p.alert),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final label = TextStyle(fontSize: 13, color: p.muted);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: p.text, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('lo que tienes', style: label),
        const SizedBox(width: 16),
        Container(
          width: 16,
          height: 6,
          decoration: BoxDecoration(
            color: p.accent,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text('lo que falta', style: label),
      ],
    );
  }
}

class _SupplyRow extends StatelessWidget {
  const _SupplyRow({
    required this.rec,
    required this.learning,
    required this.bought,
    required this.onTap,
  });

  final Recommendation rec;
  final bool learning;
  final bool bought;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final s = rec.supply;
    return Semantics(
      button: true,
      checked: bought,
      label:
          'Comprar ${withUnit(rec.toBuy, s.unit)} de ${s.name}. '
          'Tienes ${withUnit(rec.onHand, s.unit)}.${learning ? ' Kilo aún aprende este insumo.' : ''}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ExcludeSemantics(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: bought ? 0.4 : 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Row(
                children: [
                  supplyIcon(s.icon, 36),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 122,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: p.text,
                          ),
                          maxLines: 2,
                        ),
                        if (learning)
                          Text(
                            'Kilo aún aprende',
                            style: TextStyle(fontSize: 12, color: p.muted),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RangeBar(
                      fraction: rec.needed == 0 ? 1 : rec.onHand / rec.needed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 84,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (bought)
                            Icon(
                              CupertinoIcons.checkmark_alt,
                              size: 18,
                              color: p.text,
                            ),
                          Text(
                            ' ${withUnit(rec.toBuy, s.unit)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: p.text,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
