import 'package:material_ui/material_ui.dart';

import '../../core/widgets/section_card.dart';

class TranscriptCard extends StatelessWidget {
  const TranscriptCard({super.key, required this.transcript});

  final String transcript;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      header: const Text('Escuché'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '«$transcript»',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
