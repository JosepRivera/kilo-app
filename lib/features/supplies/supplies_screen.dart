import 'package:flutter/cupertino.dart';

import '../../data/store.dart';
import '../../domain/models.dart';
import '../../theme/forecast_palette.dart';
import '../../ui/format.dart';
import '../../ui/panel.dart';
import 'supply_detail_screen.dart';

class SuppliesScreen extends StatefulWidget {
  const SuppliesScreen({super.key});

  @override
  State<SuppliesScreen> createState() => _SuppliesScreenState();
}

class _SuppliesScreenState extends State<SuppliesScreen> {
  var _query = '';

  bool _matches(SupplyInfo s) =>
      s.name.toLowerCase().contains(_query.toLowerCase());

  @override
  Widget build(BuildContext context) {
    final store = KiloScope.of(context);
    final p = ForecastPalette.of(context);
    final alerts = store.engine.expiryAlerts();
    final expiring = {for (final a in alerts.reversed) a.supply.id: a.daysLeft};
    final groups = [
      for (final c in store.data.categories)
        (
          c,
          store.data.supplies
              .where((s) => s.categoryId == c.id && _matches(s))
              .toList(),
        ),
    ].where((g) => g.$2.isNotEmpty).toList();

    return ForecastPage(
      title: 'Insumos',
      children: [
        CupertinoSearchTextField(
          placeholder: 'Buscar insumo',
          backgroundColor: p.surface,
          onChanged: (q) => setState(() => _query = q),
        ),
        if (alerts.isNotEmpty && _query.isEmpty)
          Panel(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PanelHeader(
                  CupertinoIcons.exclamationmark_triangle_fill,
                  'POR VENCER',
                  color: p.alert,
                ),
                for (final (i, a) in alerts.indexed) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.only(left: 48),
                      child: PanelDivider(),
                    ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 60),
                    onPressed: () => Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (_) =>
                            SupplyDetailScreen(supplyId: a.supply.id),
                      ),
                    ),
                    child: Row(
                      children: [
                        supplyIcon(a.supply.icon, 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.supply.name,
                                style: TextStyle(fontSize: 17, color: p.text),
                              ),
                              Text(
                                'Lote ${store.engine.lotLabel(a.lot.lot)} · ${withUnit(double.parse(a.lot.remaining.toStringAsFixed(1)), a.supply.unit)}',
                                style: TextStyle(fontSize: 13, color: p.muted),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          expiryText(a.daysLeft),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: p.alert,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          CupertinoIcons.chevron_forward,
                          size: 16,
                          color: p.muted.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        if (groups.isEmpty)
          Panel(
            child: Text(
              'No hay insumos con “$_query”.',
              style: TextStyle(fontSize: 17, color: p.muted),
            ),
          ),
        for (final (c, supplies) in groups)
          Panel(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.muted,
                  ),
                ),
                for (final (i, s) in supplies.indexed) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.only(left: 48),
                      child: PanelDivider(),
                    ),
                  _SupplyTile(
                    supply: s,
                    onHand: store.engine.currentStock(s.id),
                    learning: store.engine.isLearning(s.id),
                    expiresIn: expiring[s.id],
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _SupplyTile extends StatelessWidget {
  const _SupplyTile({
    required this.supply,
    required this.onHand,
    required this.learning,
    required this.expiresIn,
  });

  final SupplyInfo supply;
  final double onHand;
  final bool learning;
  final int? expiresIn;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final subtitle = [
      supply.critical ? 'Diario' : 'Semanal',
      if (learning) 'Kilo aún aprende',
    ].join(' · ');
    final muted = TextStyle(fontSize: 13, color: p.muted);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(0, 60),
      onPressed: () => Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) => SupplyDetailScreen(supplyId: supply.id),
        ),
      ),
      child: Row(
        children: [
          supplyIcon(supply.icon, 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supply.name,
                  style: TextStyle(fontSize: 17, color: p.text),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      if (expiresIn != null)
                        TextSpan(
                          text:
                              '${expiryText(expiresIn!)[0].toUpperCase()}${expiryText(expiresIn!).substring(1)} · ',
                          style: muted.copyWith(
                            color: p.alert,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      TextSpan(text: subtitle, style: muted),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(
            withUnit(onHand, supply.unit),
            style: TextStyle(
              fontSize: 17,
              color: p.muted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            CupertinoIcons.chevron_forward,
            size: 16,
            color: p.muted.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}
