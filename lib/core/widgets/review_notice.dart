import 'package:material_ui/material_ui.dart';

import '../theme/kilo_colors.dart';

class ReviewNotice extends StatelessWidget {
  const ReviewNotice({super.key, required this.message, required this.actions});

  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = KiloColors.of(context);
    final theme = Theme.of(context);
    return ColoredBox(
      color: colors.alertGround,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: colors.alert,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Revisar',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.alert,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(message, style: theme.textTheme.bodyMedium),
            Wrap(spacing: 8, children: actions),
          ],
        ),
      ),
    );
  }
}
