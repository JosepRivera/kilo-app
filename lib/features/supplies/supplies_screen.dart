import 'package:flutter/cupertino.dart';

import '../../data/catalog.dart';
import '../../data/supplies.dart';
import '../../theme/forecast_palette.dart';
import '../../ui/panel.dart';
import 'supply_detail_screen.dart';

/// "Insumos": the restaurant's catalog grouped by category.
class SuppliesScreen extends StatefulWidget {
  const SuppliesScreen({super.key});

  @override
  State<SuppliesScreen> createState() => _SuppliesScreenState();
}

class _SuppliesScreenState extends State<SuppliesScreen> {
  var _query = '';

  bool _matches(CatalogSupply s) =>
      s.name.toLowerCase().contains(_query.toLowerCase());

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final categories = [
      for (final c in demoCatalog)
        if (c.supplies.any(_matches))
          Category(c.name, c.supplies.where(_matches).toList()),
    ];

    return ForecastPage(
      title: 'Insumos',
      children: [
        CupertinoSearchTextField(
          placeholder: 'Buscar insumo',
          backgroundColor: p.surface,
          onChanged: (q) => setState(() => _query = q),
        ),
        if (categories.isEmpty)
          Panel(
            child: Text(
              'No hay insumos con “$_query”.',
              style: TextStyle(fontSize: 17, color: p.muted),
            ),
          ),
        for (final c in categories)
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
                for (final (i, s) in c.supplies.indexed) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.only(left: 48),
                      child: PanelDivider(),
                    ),
                  _SupplyTile(supply: s),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _SupplyTile extends StatelessWidget {
  const _SupplyTile({required this.supply});

  final CatalogSupply supply;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final expiring = supply.lots.any((l) => l.daysToExpiry <= 1);
    final subtitle = [
      supply.critical ? 'Diario' : 'Semanal',
      if (supply.isLearning) 'Kilo aún aprende',
    ].join(' · ');

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(0, 60),
      onPressed: () => Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) => SupplyDetailScreen(supply: supply),
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
                Text(subtitle, style: TextStyle(fontSize: 13, color: p.muted)),
              ],
            ),
          ),
          if (expiring) ...[
            Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              size: 16,
              color: p.alert,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            '${formatQty(supply.onHand)} ${supply.unit}',
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
