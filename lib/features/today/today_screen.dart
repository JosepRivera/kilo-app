import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../theme/forecast_palette.dart';
import '../../data/supplies.dart';

/// "Hoy": the morning purchase list, read like a daily forecast.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final _bought = <String>{};

  void _toggle(Supply i) {
    HapticFeedback.selectionClick();
    setState(
      () => _bought.contains(i.name)
          ? _bought.remove(i.name)
          : _bought.add(i.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final alert = demoShoppingList.firstWhere((i) => i.expiryAlert != null);

    return CupertinoPageScaffold(
      backgroundColor: p.background,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Compra de hoy'),
            backgroundColor: p.background.withValues(alpha: 0.9),
            border: null,
          ),
          SliverPadding(
            // Bottom room for the floating tab bar.
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
            sliver: SliverList.list(
              children: [
                _Panel(
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
                const SizedBox(height: 12),
                _Panel(
                  color: p.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.calendar,
                            size: 16,
                            color: p.muted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'PARA LOS PRÓXIMOS 3 DÍAS',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: p.muted,
                            ),
                          ),
                        ],
                      ),
                      for (final i in demoShoppingList) ...[
                        Container(
                          height: 0.5,
                          color: p.track,
                          margin: const EdgeInsets.only(top: 10),
                        ),
                        _SupplyRow(
                          supply: i,
                          bought: _bought.contains(i.name),
                          onTap: () => _toggle(i),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: p.text,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'lo que tienes',
                            style: TextStyle(fontSize: 13, color: p.muted),
                          ),
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
                          Text(
                            'lo que falta',
                            style: TextStyle(fontSize: 13, color: p.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Panel(
                  color: p.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.checkmark_seal_fill,
                            size: 16,
                            color: p.muted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'YA ALCANZA',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: p.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );
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
    final onHand = supply.onHand / supply.needed;
    return Semantics(
      button: true,
      checked: bought,
      label:
          'Comprar ${formatQty(supply.toBuy)} ${supply.unit} de ${supply.name}. Tienes ${formatQty(supply.onHand)}.'
          '${supply.isLearning ? ' Kilo aún aprende este insumo.' : ''}',
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
                    child: LayoutBuilder(
                      builder: (_, box) => SizedBox(
                        height: 12,
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: p.track,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            Positioned(
                              left: box.maxWidth * onHand,
                              right: 0,
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: p.accent,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                            Positioned(
                              left: (box.maxWidth * onHand - 5).clamp(
                                0,
                                box.maxWidth - 10,
                              ),
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: p.text,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: p.surface,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
