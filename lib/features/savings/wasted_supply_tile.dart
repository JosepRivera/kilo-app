import 'package:material_ui/material_ui.dart';

import '../../core/formatters.dart';
import '../../core/widgets/supply_icon.dart';
import '../../data/models/wasted_supply.dart';

class WastedSupplyTile extends StatelessWidget {
  const WastedSupplyTile({super.key, required this.item});

  final WastedSupply item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: SupplyIcon(icon: item.supply.icon),
      title: Text(item.supply.name),
      trailing: Text(
        soles(item.soles),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
