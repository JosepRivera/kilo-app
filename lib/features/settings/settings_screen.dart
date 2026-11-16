import 'package:material_ui/material_ui.dart';

import '../../core/widgets/async_view.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/show_message.dart';
import '../../core/widgets/text_prompt_dialog.dart';
import 'closed_weekdays_picker.dart';
import 'settings_snapshot.dart';
import 'settings_view_model.dart';
import '../stock_close/no_consumption_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.viewModel,
    required this.onOpenCategories,
    required this.onOpenRecordingMode,
  });

  final SettingsViewModel viewModel;
  final void Function(BuildContext context) onOpenCategories;
  final void Function(BuildContext context) onOpenRecordingMode;

  Future<void> _report(BuildContext context, Future<String?> change) async {
    final error = await change;
    if (error != null && context.mounted) showMessage(context, error);
  }

  Future<void> _rename(BuildContext context, String current) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => TextPromptDialog(
        title: 'Nombre del restaurante',
        label: 'Nombre',
        initialText: current,
      ),
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    await _report(context, viewModel.rename(name));
  }

  Future<void> _confirmNoConsumption(BuildContext context) async {
    final confirmed = await NoConsumptionDialog.confirm(context);
    if (!confirmed || !context.mounted) return;
    final error = await viewModel.markNoConsumption();
    if (!context.mounted) return;
    showMessage(context, error ?? 'Listo: hoy quedó sin consumo.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: AsyncView<SettingsSnapshot>(
        source: viewModel,
        builder: (context, snapshot) => ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            SectionCard(
              header: const Text('Tu restaurante'),
              children: [
                ListTile(
                  title: const Text('Nombre'),
                  subtitle: Text(snapshot.restaurant.name),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _rename(context, snapshot.restaurant.name),
                ),
                ClosedWeekdaysPicker(
                  closed: snapshot.restaurant.closedWeekdays,
                  onToggle: (weekday) =>
                      _report(context, viewModel.toggleClosedWeekday(weekday)),
                ),
              ],
            ),
            SectionCard(
              header: const Text('Insumos'),
              children: [
                ListTile(
                  title: const Text('Compras y gasto por categoría'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onOpenCategories(context),
                ),
                ListTile(
                  title: const Text('Qué se cuenta cada noche'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onOpenRecordingMode(context),
                ),
              ],
            ),
            SectionCard(
              children: [
                ListTile(
                  leading: const Icon(Icons.event_busy_outlined),
                  title: const Text('Hoy no hubo consumo'),
                  onTap: () => _confirmNoConsumption(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
