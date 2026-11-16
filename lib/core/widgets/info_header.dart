import 'package:material_ui/material_ui.dart';

import '../theme/kilo_theme.dart';

class InfoHeader extends StatelessWidget {
  const InfoHeader({super.key, required this.title, required this.info});

  final String title;
  final String info;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title)),
        Tooltip(
          message: info,
          triggerMode: TooltipTriggerMode.tap,
          showDuration: const Duration(seconds: 8),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(12),
          child: const SizedBox.square(
            dimension: KiloTheme.minTapTarget,
            child: Icon(Icons.info_outline, semanticLabel: 'Más información'),
          ),
        ),
      ],
    );
  }
}
