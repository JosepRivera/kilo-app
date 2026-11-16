import 'package:material_ui/material_ui.dart';

import '../../core/formatters.dart';
import '../../core/theme/kilo_colors.dart';

class CloseSuggestionNotice extends StatelessWidget {
  const CloseSuggestionNotice({
    super.key,
    required this.heard,
    required this.suggested,
    required this.unit,
    required this.onAccept,
    required this.onKeep,
  });

  final double? heard;
  final double suggested;
  final String unit;
  final VoidCallback onAccept;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    final heardText = heard == null ? 'nada' : withUnit(heard!, unit);
    final suggestedText = withUnit(suggested, unit);
    return ColoredBox(
      color: KiloColors.of(context).ground,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escuché «$heardText», pero según tu historial quedarían unos '
              '$suggestedText. ¿Quisiste decir $suggestedText?',
            ),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: onAccept,
                  child: Text('Sí, $suggestedText'),
                ),
                TextButton(onPressed: onKeep, child: Text('No, $heardText')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
