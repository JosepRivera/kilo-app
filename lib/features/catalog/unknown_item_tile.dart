import 'package:material_ui/material_ui.dart';

import '../../core/formatters.dart';
import '../../core/theme/kilo_colors.dart';

class UnknownItemTile extends StatelessWidget {
  const UnknownItemTile({
    super.key,
    required this.spoken,
    required this.onCreate,
    required this.onRemove,
  });

  final String spoken;
  final VoidCallback? onCreate;
  final VoidCallback? onRemove;

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
                  '${capitalize(spoken)} no está en tu catálogo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: onCreate,
                      child: const Text('Crear insumo'),
                    ),
                    TextButton(
                      onPressed: onRemove,
                      style: TextButton.styleFrom(foregroundColor: alert),
                      child: const Text('Quitar'),
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
