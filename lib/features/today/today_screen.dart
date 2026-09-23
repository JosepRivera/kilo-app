import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../data/supplies.dart';
import '../../theme/forecast_palette.dart';
import '../../ui/panel.dart';
import '../../ui/range_bar.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final _bought = <String>{};

  void _toggle(Supply s) {
    HapticFeedback.selectionClick();
    setState(
      () => _bought.contains(s.name)
          ? _bought.remove(s.name)
          : _bought.add(s.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final alert = demoShoppingList.firstWhere((s) => s.expiryAlert != null);

    return ForecastPage(
      title: 'Compra de hoy',
      children: [
        Panel(
          color: p.alertBackground,
          child: Row(
            children: [
              supplyIcon(alert.icon, 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.expiryAlert!,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: p.alert,
                      ),
                    ),
                    Text(
                      '${alert.name} · úsalo primero',
                      style: TextStyle(fontSize: 15, color: p.alert),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: p.alert,
              ),
            ],
          ),
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelHeader(
                CupertinoIcons.calendar,
                'PARA LOS PRÓXIMOS 3 DÍAS',
              ),
              for (final s in demoShoppingList) ...[
                const PanelDivider(),
                _SupplyRow(
                  supply: s,
                  bought: _bought.contains(s.name),
                  onTap: () => _toggle(s),
                ),
              ],
              const SizedBox(height: 8),
              const _Legend(),
            ],
          ),
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelHeader(
                CupertinoIcons.checkmark_seal_fill,
                'YA ALCANZA',
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final c in demoCovered.entries)
                    Column(
                      children: [
                        supplyIcon(c.value, 36),
                        const SizedBox(height: 4),
                        Text(
                          c.key,
                          style: TextStyle(fontSize: 13, color: p.text),
                        ),
                      ],
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
    required this.supply,
    required this.bought,
    required this.onTap,
  });

  final Supply supply;
  final bool bought;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    return Semantics(
      button: true,
      checked: bought,
      label:
          'Comprar ${formatQty(supply.toBuy)} ${supply.unit} de ${supply.name}. '
          'Tienes ${formatQty(supply.onHand)}.${supply.isLearning ? ' Kilo aún aprende este insumo.' : ''}',
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
                  supplyIcon(supply.icon, 36),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 122,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          supply.name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: p.text,
                          ),
                          maxLines: 2,
                        ),
                        if (supply.isLearning)
                          Text(
                            'Kilo aún aprende',
                            style: TextStyle(fontSize: 12, color: p.muted),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RangeBar(fraction: supply.onHand / supply.needed),
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
                            ' ${formatQty(supply.toBuy)} ${supply.unit}',
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
