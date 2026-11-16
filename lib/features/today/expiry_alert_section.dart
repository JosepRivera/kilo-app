import 'package:material_ui/material_ui.dart';

import '../../core/theme/kilo_colors.dart';
import '../../core/widgets/section_card.dart';
import '../../data/models/expiry_alert.dart';
import 'expiring_screen.dart';
import 'expiry_alert_row.dart';

class ExpiryAlertSection extends StatelessWidget {
  const ExpiryAlertSection({
    super.key,
    required this.alerts,
    required this.today,
  });

  final List<ExpiryAlert> alerts;
  final DateTime today;

  void _openAll(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExpiringScreen(alerts: alerts, today: today),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = KiloColors.of(context);
    return SectionCard(
      color: colors.alertGround,
      children: [
        ExpiryAlertRow(alert: alerts.first, today: today),
        if (alerts.length > 1)
          ListTile(
            title: Text(
              'Ver todo lo que vence (${alerts.length})',
              style: TextStyle(color: colors.alert),
            ),
            trailing: Icon(Icons.chevron_right, color: colors.alert),
            onTap: () => _openAll(context),
          ),
      ],
    );
  }
}
