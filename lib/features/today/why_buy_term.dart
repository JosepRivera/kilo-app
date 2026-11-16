import 'package:material_ui/material_ui.dart';

class WhyBuyTerm extends StatelessWidget {
  const WhyBuyTerm({
    super.key,
    required this.title,
    required this.value,
    this.detail,
    this.emphasis,
  });

  final String title;
  final String value;
  final String? detail;
  final Color? emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = this.detail;
    final style = theme.textTheme.bodyLarge?.copyWith(
      color: emphasis,
      fontWeight: emphasis == null ? null : FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: style),
                  if (detail != null)
                    Text(
                      detail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(value, style: style),
          ],
        ),
      ),
    );
  }
}
