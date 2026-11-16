import 'package:material_ui/material_ui.dart';

import '../../core/theme/kilo_colors.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_card.dart';
import '../../data/models/supply.dart';
import 'supplies_catalog.dart';
import 'supplies_view_model.dart';
import 'supply_row.dart';

class SuppliesScreen extends StatelessWidget {
  const SuppliesScreen({
    super.key,
    required this.viewModel,
    required this.onOpenSupply,
  });

  final SuppliesViewModel viewModel;
  final void Function(BuildContext context, Supply supply) onOpenSupply;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: false, title: const Text('Insumos')),
      body: AsyncView<SuppliesCatalog>(
        source: viewModel,
        builder: (context, catalog) => RefreshIndicator(
          onRefresh: viewModel.load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: SearchBar(
                    hintText: 'Buscar insumo',
                    leading: const Icon(Icons.search),
                    elevation: const WidgetStatePropertyAll(0),
                    backgroundColor: WidgetStatePropertyAll(
                      KiloColors.of(context).module,
                    ),
                    onChanged: viewModel.search,
                  ),
                ),
              ),
              ListenableBuilder(
                listenable: viewModel,
                builder: (context, _) => _sections(context, catalog),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sections(BuildContext context, SuppliesCatalog catalog) {
    final sections = viewModel.sections;
    final expiring = viewModel.expiring;
    if (sections.isEmpty) {
      return SliverToBoxAdapter(
        child: catalog.supplies.isEmpty
            ? const EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'Aún no tienes insumos',
                message: 'Se agregan solos con tu primer conteo o compra.',
              )
            : EmptyState(
                icon: Icons.search_off,
                title: 'Sin resultados',
                message:
                    'No hay insumos que coincidan con «${viewModel.query}».',
              ),
      );
    }
    final alert = KiloColors.of(context).alert;
    return SliverList.builder(
      itemCount: sections.length + (expiring.isEmpty ? 0 : 1),
      itemBuilder: (context, index) {
        if (expiring.isNotEmpty && index == 0) {
          return SectionCard(
            header: Row(
              children: [
                Icon(Icons.warning_rounded, size: 18, color: alert),
                const SizedBox(width: 6),
                Text('Por vencer', style: TextStyle(color: alert)),
              ],
            ),
            children: [
              for (final supply in expiring)
                SupplyRow(
                  supply: supply,
                  onTap: () => onOpenSupply(context, supply),
                ),
            ],
          );
        }
        final section = sections[index - (expiring.isEmpty ? 0 : 1)];
        return SectionCard(
          header: Text(section.title),
          children: [
            for (final supply in section.supplies)
              SupplyRow(
                supply: supply,
                onTap: () => onOpenSupply(context, supply),
              ),
          ],
        );
      },
    );
  }
}
