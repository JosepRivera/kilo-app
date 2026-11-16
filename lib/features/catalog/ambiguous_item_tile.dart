import 'package:material_ui/material_ui.dart';

import '../../core/theme/kilo_colors.dart';
import '../../data/models/catalog_candidate.dart';

class AmbiguousItemTile extends StatelessWidget {
  const AmbiguousItemTile({
    super.key,
    required this.spoken,
    required this.candidates,
    required this.onPick,
  });

  final String spoken;
  final List<CatalogCandidate> candidates;
  final ValueChanged<CatalogCandidate>? onPick;

  @override
  Widget build(BuildContext context) {
    final alert = KiloColors.of(context).alert;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: Icon(Icons.help, color: alert, size: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Cuál $spoken?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final candidate in candidates)
                      ActionChip(
                        label: Text(candidate.name),
                        onPressed: onPick == null
                            ? null
                            : () => onPick!(candidate),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
