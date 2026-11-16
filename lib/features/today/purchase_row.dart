import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/app_name.dart';
import '../../core/formatters.dart';
import '../../core/theme/kilo_colors.dart';
import '../../core/widgets/range_bar.dart';
import '../../core/widgets/supply_icon.dart';
import '../../data/models/purchase_suggestion.dart';

class PurchaseRow extends StatelessWidget {
  const PurchaseRow({
    super.key,
    required this.item,
    required this.bought,
    required this.onToggle,
    required this.onExplain,
  });

  final PurchaseSuggestion item;
  final bool bought;
  final VoidCallback? onToggle;
  final VoidCallback onExplain;

  void _toggle() {
    HapticFeedback.selectionClick();
    onToggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = KiloColors.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final supply = item.supply;
    final toBuy = withUnit(item.recommendation.toBuy, supply.unit);
    final onHand = withUnit(item.recommendation.onHand, supply.unit);
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: '${supply.name}, comprar $toBuy, tienes $onHand',
            hint: 'Explica por qué',
            excludeSemantics: true,
            child: InkWell(
              onTap: onExplain,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 0, 12),
                child: Row(
                  children: [
                    Opacity(
                      opacity: bought ? 0.4 : 1,
                      child: SupplyIcon(icon: supply.icon, size: 36),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Expanded(
                                child: Text(
                                  supply.name,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    decoration: bought
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                toBuy,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: bought ? muted : colors.accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (bought)
                            Text(
                              'Comprado',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.good,
                              ),
                            )
                          else ...[
                            RangeBar(
                              fraction: item.recommendation.coveredFraction,
                            ),
                            if (supply.learning)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '$appName aún aprende',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: muted,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onToggle == null ? null : _toggle,
          tooltip: bought ? 'Comprado' : 'Marcar como comprado',
          color: bought ? colors.good : colors.track,
          disabledColor: colors.good,
          icon: Icon(bought ? Icons.check_circle : Icons.circle_outlined),
        ),
      ],
    );
  }
}
