import 'package:material_ui/material_ui.dart';

import '../../core/app_name.dart';
import '../../core/formatters.dart';
import '../../core/theme/kilo_colors.dart';
import '../../core/widgets/supply_icon.dart';
import '../../data/models/supply.dart';

class SupplyRow extends StatelessWidget {
  const SupplyRow({super.key, required this.supply, required this.onTap});

  final Supply supply;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final cadence = supply.critical ? 'Diario' : 'Semanal';
    final expires = supply.expiresInDays;
    return ListTile(
      onTap: onTap,
      leading: SupplyIcon(icon: supply.icon),
      title: Text(supply.name),
      subtitle: Text.rich(
        TextSpan(
          children: [
            if (expires != null)
              TextSpan(
                text: '${capitalize(expiryText(expires))} · ',
                style: TextStyle(color: KiloColors.of(context).alert),
              ),
            TextSpan(text: cadence),
            if (expires == null && supply.learning)
              const TextSpan(text: ' · $appName aún aprende'),
          ],
        ),
      ),
      trailing: Text(
        withUnit(supply.stock, supply.unit),
        style: theme.textTheme.bodyLarge?.copyWith(color: muted),
      ),
    );
  }
}
