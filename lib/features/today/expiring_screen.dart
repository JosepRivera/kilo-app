import 'package:material_ui/material_ui.dart';

import '../../core/app_name.dart';
import '../../core/widgets/info_header.dart';
import '../../core/widgets/section_card.dart';
import '../../data/models/expiry_alert.dart';
import 'expiry_alert_row.dart';

class ExpiringScreen extends StatelessWidget {
  const ExpiringScreen({super.key, required this.alerts, required this.today});

  final List<ExpiryAlert> alerts;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Por vencer')),
      body: ListView(
        children: [
          SectionCard(
            header: const InfoHeader(
              title: 'Por vencer',
              info: '$appName asume que se usa primero lo más antiguo.',
            ),
            children: [
              for (final alert in alerts)
                ExpiryAlertRow(alert: alert, today: today),
            ],
          ),
        ],
      ),
    );
  }
}
