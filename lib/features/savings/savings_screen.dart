import 'package:material_ui/material_ui.dart';

import '../../core/formatters.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/bar_chart.dart';
import '../../core/widgets/info_header.dart';
import '../../core/widgets/section_card.dart';
import '../../data/models/savings.dart';
import 'month_comparison.dart';
import 'savings_view_model.dart';
import 'wasted_supply_tile.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key, required this.viewModel});

  final SavingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: false, title: const Text('Ahorro')),
      body: AsyncView<Savings>(
        source: viewModel,
        builder: (context, savings) => RefreshIndicator(
          onRefresh: viewModel.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              SectionCard(
                children: [
                  MonthComparison(
                    current: savings.current,
                    previous: savings.previous,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                    child: BarChart(
                      values: [for (final m in savings.months) m.soles],
                      labels: [
                        for (final m in savings.months) monthLabel(m.month),
                      ],
                      valueLabels: [
                        for (final m in savings.months) soles(m.soles),
                      ],
                      highlighted: savings.months.length - 1,
                      semanticLabel: [
                        'Perdido por mes',
                        for (final m in savings.months)
                          '${monthLabel(m.month)} ${soles(m.soles)}',
                      ].join(', '),
                    ),
                  ),
                ],
              ),
              if (savings.topWasted.isNotEmpty)
                SectionCard(
                  header: const InfoHeader(
                    title: 'Lo que más se venció este mes',
                    info:
                        'Es el costo de compra de lo que se venció, no la '
                        'ganancia perdida.',
                  ),
                  children: [
                    for (final item in savings.topWasted)
                      WastedSupplyTile(item: item),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
