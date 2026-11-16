import 'package:material_ui/material_ui.dart';

import '../../core/formatters.dart';
import '../../core/theme/kilo_colors.dart';
import '../../core/widgets/supply_icon.dart';
import '../../data/models/expiry_alert.dart';

class ExpiryAlertRow extends StatelessWidget {
  const ExpiryAlertRow({super.key, required this.alert, required this.today});

  final ExpiryAlert alert;
  final DateTime today;

  String get _title {
    final expiry = expiryText(alert.daysLeft);
    if (alert.lots.length != 1) {
      return '${alert.lots.length} lotes '
          '${expiry.replaceFirst('vence', 'vencen')}';
    }
    return 'El lote ${lotLabel(alert.lots.first.purchasedOn, today)} $expiry';
  }

  @override
  Widget build(BuildContext context) {
    final alertColor = KiloColors.of(context).alert;
    final textTheme = Theme.of(context).textTheme;
    final supply = alert.supply;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: MergeSemantics(
        child: Row(
          children: [
            SupplyIcon(icon: supply.icon, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: textTheme.titleMedium?.copyWith(
                      color: alertColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${supply.name} · quedan '
                    '${withUnit(alert.remaining, supply.unit)} · úsalo primero',
                    style: textTheme.bodyMedium?.copyWith(color: alertColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ExcludeSemantics(
              child: Icon(Icons.warning_rounded, color: alertColor),
            ),
          ],
        ),
      ),
    );
  }
}
