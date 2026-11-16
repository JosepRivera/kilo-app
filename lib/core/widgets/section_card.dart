import 'package:material_ui/material_ui.dart';

import '../theme/kilo_colors.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.header,
    this.color,
    required this.children,
  });

  final Widget? header;
  final Color? color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final header = this.header;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 0, 4),
              child: DefaultTextStyle.merge(
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                child: Semantics(header: true, child: header),
              ),
            ),
          Material(
            color: color ?? KiloColors.of(context).module,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, child) in children.indexed) ...[
                  if (index > 0) const Divider(height: 1, indent: 16),
                  child,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
