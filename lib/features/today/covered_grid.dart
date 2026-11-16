import 'package:material_ui/material_ui.dart';

import '../../core/widgets/supply_icon.dart';
import '../../data/models/supply.dart';

class CoveredGrid extends StatelessWidget {
  const CoveredGrid({super.key, required this.supplies});

  final List<Supply> supplies;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caption = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 12,
        children: [
          for (final supply in supplies)
            SizedBox(
              width: 72,
              child: Column(
                children: [
                  SupplyIcon(icon: supply.icon),
                  const SizedBox(height: 4),
                  Text(
                    supply.name,
                    style: caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
