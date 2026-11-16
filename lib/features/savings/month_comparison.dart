import 'package:material_ui/material_ui.dart';

import '../../core/formatters.dart';
import '../../core/theme/kilo_colors.dart';

class MonthComparison extends StatelessWidget {
  const MonthComparison({
    super.key,
    required this.current,
    required this.previous,
  });

  final double current;
  final double previous;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = KiloColors.of(context);
    final diff = previous - current;
    final improved = diff >= 0;
    final color = improved ? colors.good : colors.alert;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Este mes perdiste',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            Text(
              soles(current),
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (previous > 0)
              Row(
                children: [
                  Icon(
                    improved ? Icons.south_east : Icons.north_east,
                    size: 20,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      improved
                          ? '${soles(diff)} menos que el mes pasado'
                          : '${soles(-diff)} más que el mes pasado',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
