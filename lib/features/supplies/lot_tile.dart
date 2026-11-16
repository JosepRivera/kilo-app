import 'package:material_ui/material_ui.dart';

import '../../core/formatters.dart';
import '../../core/theme/kilo_colors.dart';
import '../../data/models/lot.dart';

class LotTile extends StatelessWidget {
  const LotTile({
    super.key,
    required this.lot,
    required this.unit,
    required this.today,
  });

  final Lot lot;
  final String unit;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urgent = lot.daysLeft <= 1;
    return ListTile(
      title: Text('Lote ${lotLabel(lot.purchasedOn, today)}'),
      subtitle: Text('Vence el ${shortDate(lot.expiresOn)}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(withUnit(lot.remaining, unit), style: theme.textTheme.bodyLarge),
          Text(
            expiryText(lot.daysLeft),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: urgent
                  ? KiloColors.of(context).alert
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
