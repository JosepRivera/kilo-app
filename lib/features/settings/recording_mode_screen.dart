import 'package:material_ui/material_ui.dart';

import '../../core/widgets/async_view.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/info_header.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/show_message.dart';
import '../../core/widgets/supply_icon.dart';
import '../../data/models/supply.dart';
import '../supplies/supplies_catalog.dart';
import 'recording_mode_view_model.dart';

class RecordingModeScreen extends StatelessWidget {
  const RecordingModeScreen({super.key, required this.viewModel});

  final RecordingModeViewModel viewModel;

  Future<void> _toggle(BuildContext context, Supply supply, bool value) async {
    final error = await viewModel.setCritical(supply, value);
    if (error != null && context.mounted) showMessage(context, error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro diario')),
      body: AsyncView<SuppliesCatalog>(
        source: viewModel,
        builder: (context, _) => ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            final sections = viewModel.sections;
            if (sections.isEmpty) {
              return const EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'Aún no tienes insumos',
                message: 'Se agregan solos con tu primer conteo o compra.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: sections.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(32, 8, 16, 0),
                    child: InfoHeader(
                      title: 'Qué se cuenta cada noche',
                      info:
                          'Activa los insumos caros o que se malogran rápido. '
                          'Los demás se cuentan una vez por semana.',
                    ),
                  );
                }
                final section = sections[index - 1];
                return SectionCard(
                  header: Text(section.title),
                  children: [
                    for (final supply in section.supplies)
                      SwitchListTile(
                        secondary: SupplyIcon(icon: supply.icon, size: 28),
                        title: Text(supply.name),
                        subtitle: Text(
                          supply.critical
                              ? 'Se cuenta cada noche'
                              : 'Se cuenta una vez por semana',
                        ),
                        value: supply.critical,
                        onChanged: viewModel.isSaving(supply)
                            ? null
                            : (value) => _toggle(context, supply, value),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
