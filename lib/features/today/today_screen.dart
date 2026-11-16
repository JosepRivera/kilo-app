import 'package:material_ui/material_ui.dart';

import '../../core/app_name.dart';
import '../../core/formatters.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/info_header.dart';
import '../../core/widgets/section_card.dart';
import '../../data/models/today_overview.dart';
import 'covered_grid.dart';
import 'expiry_alert_section.dart';
import 'purchase_row.dart';
import 'today_view_model.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({
    super.key,
    required this.viewModel,
    required this.onOpenSettings,
    required this.onExplain,
    required this.onStartFirstCount,
  });

  final TodayViewModel viewModel;
  final void Function(BuildContext context) onOpenSettings;
  final void Function(BuildContext context, String supplyId) onExplain;
  final void Function(BuildContext context) onStartFirstCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            final day = viewModel.value?.day;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Compra de hoy'),
                if (day != null)
                  Text(
                    capitalize(longDate(day)),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: () => onOpenSettings(context),
            tooltip: 'Ajustes',
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: AsyncView<TodayOverview>(
        source: viewModel,
        builder: (context, overview) => RefreshIndicator(
          onRefresh: viewModel.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 96),
            children: viewModel.needsFirstCount
                ? [_firstCount(context)]
                : _sections(context, overview),
          ),
        ),
      ),
    );
  }

  Widget _firstCount(BuildContext context) {
    return SectionCard(
      children: [
        EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Empieza contando lo que tienes',
          message:
              'Dicta o anota tu stock de ahora. Con ese primer conteo '
              '$appName arma tu lista de insumos.',
          actionLabel: 'Hacer el primer conteo',
          onAction: () => onStartFirstCount(context),
        ),
      ],
    );
  }

  List<Widget> _sections(BuildContext context, TodayOverview overview) {
    return [
      if (overview.alerts.isNotEmpty)
        ExpiryAlertSection(alerts: overview.alerts, today: overview.day),
      if (overview.toBuy.isEmpty)
        SectionCard(
          children: [
            EmptyState(
              icon: Icons.check_circle_outline,
              title: overview.covered.isEmpty
                  ? 'Hoy no toca ir al mercado'
                  : 'Ya tienes todo lo de hoy',
              message: '$appName te avisa cuando toque la próxima compra.',
            ),
          ],
        )
      else
        SectionCard(
          header: const InfoHeader(
            title: 'Hasta tu próxima compra',
            info:
                'El punto es lo que tienes; lo azul, lo que falta. '
                'Toca una fila para ver cómo se calculó.',
          ),
          children: [
            for (final item in overview.toBuy)
              PurchaseRow(
                item: item,
                bought: viewModel.isBought(item),
                onToggle: item.bought
                    ? null
                    : () => viewModel.toggleBought(item),
                onExplain: () => onExplain(context, item.supply.id),
              ),
          ],
        ),
      if (overview.covered.isNotEmpty)
        SectionCard(
          header: const Text('Ya alcanza'),
          children: [CoveredGrid(supplies: overview.covered)],
        ),
    ];
  }
}
