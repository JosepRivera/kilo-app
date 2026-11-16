import 'package:material_ui/material_ui.dart';

import '../theme/kilo_colors.dart';

class BarChart extends StatelessWidget {
  const BarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.highlighted,
    required this.semanticLabel,
    this.valueLabels,
    this.barHeight = 120,
  });

  final List<double> values;
  final List<String> labels;
  final int highlighted;
  final String semanticLabel;
  final List<String>? valueLabels;
  final double barHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = KiloColors.of(context).accent;
    final caption = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final peak = values.fold<double>(0, (max, v) => v > max ? v : max);
    final valueLabels = this.valueLabels;
    return Semantics(
      label: semanticLabel,
      container: true,
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final (index, value) in values.indexed)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (valueLabels != null)
                        Text(valueLabels[index], style: caption, maxLines: 1),
                      const SizedBox(height: 4),
                      Container(
                        height: peak > 0 ? 2 + barHeight * value / peak : 2,
                        decoration: BoxDecoration(
                          color: index == highlighted
                              ? accent
                              : accent.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(labels[index], style: caption, maxLines: 1),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
