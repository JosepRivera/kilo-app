import 'package:material_ui/material_ui.dart';

import '../../core/app_name.dart';
import '../../core/formatters.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/supply_icon.dart';
import '../../data/models/supply.dart';

class SupplySummaryCard extends StatelessWidget {
  const SupplySummaryCard({super.key, required this.supply});

  final Supply supply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return SectionCard(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quedan', style: TextStyle(color: muted)),
                      Text(
                        withUnit(supply.stock, supply.unit),
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SupplyIcon(icon: supply.icon, size: 72),
            ],
          ),
        ),
        if (supply.learning)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: supply.realDays / Supply.learningDays,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 8),
                Text(
                  '$appName aún aprende · ${supply.realDays} de '
                  '${Supply.learningDays} días',
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
