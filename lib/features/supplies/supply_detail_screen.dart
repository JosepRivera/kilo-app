import 'package:material_ui/material_ui.dart';

import '../../core/app_name.dart';
import '../../core/day.dart';
import '../../core/formatters.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/bar_chart.dart';
import '../../core/widgets/info_header.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/show_message.dart';
import '../../data/models/supply_detail.dart';
import 'lot_tile.dart';
import 'peak_days.dart';
import 'recent_day_tile.dart';
import 'supply_detail_view_model.dart';
import 'supply_summary_card.dart';

class SupplyDetailScreen extends StatelessWidget {
  const SupplyDetailScreen({
    super.key,
    required this.viewModel,
    required this.title,
  });

  static const _peaks = PeakDays();

  final SupplyDetailViewModel viewModel;
  final String title;

  Future<void> _setCritical(BuildContext context, bool critical) async {
    final error = await viewModel.setCritical(critical);
    if (error != null && context.mounted) showMessage(context, error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AsyncView<SupplyDetail>(
        source: viewModel,
        builder: (context, detail) => RefreshIndicator(
          onRefresh: viewModel.load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: _sections(context, detail),
          ),
        ),
      ),
    );
  }

  List<Widget> _sections(BuildContext context, SupplyDetail detail) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final supply = detail.supply;
    final today = detail.week.isEmpty
        ? businessDay(DateTime.now())
        : detail.week.first.day;
    final peaks = _peaks.sentence(detail.week);
    return [
      SupplySummaryCard(supply: supply),
      SectionCard(
        header: const Text('Uso esperado esta semana'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: BarChart(
              values: [for (final day in detail.week) day.amount],
              labels: [
                for (final (index, day) in detail.week.indexed)
                  index == 0 ? 'Hoy' : weekdayShort[day.day.weekday - 1],
              ],
              highlighted: 0,
              semanticLabel: [
                'Uso esperado por día',
                for (final day in detail.week)
                  '${weekdayLong[day.day.weekday - 1]} '
                      '${withUnit(day.amount, supply.unit)}',
              ].join(', '),
            ),
          ),
          if (peaks != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                peaks,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            ),
        ],
      ),
      if (detail.lots.isNotEmpty)
        SectionCard(
          header: const Text('Lotes'),
          children: [
            for (final lot in detail.lots)
              LotTile(lot: lot, unit: supply.unit, today: today),
          ],
        ),
      SectionCard(
        header: const InfoHeader(
          title: 'Últimos días',
          info:
              '«Estimado» es un día sin cierre: $appName repartió la '
              'diferencia y lo cuenta a medias mientras aprende.',
        ),
        children: [
          for (final day in detail.recent)
            RecentDayTile(day: day, unit: supply.unit),
        ],
      ),
      SectionCard(
        header: const Text('Cómo se registra'),
        children: [
          ListenableBuilder(
            listenable: viewModel,
            builder: (context, _) => SwitchListTile(
              title: const Text('Contar cada noche'),
              subtitle: Text(
                supply.critical
                    ? 'Insumo crítico: se cuenta a diario'
                    : 'Insumo secundario: se cuenta una vez por semana',
              ),
              value: supply.critical,
              onChanged: viewModel.isSaving
                  ? null
                  : (critical) => _setCritical(context, critical),
            ),
          ),
          ListTile(
            title: const Text('Unidad'),
            trailing: Text(supply.unit, style: theme.textTheme.bodyLarge),
          ),
          for (final MapEntry(key: phrase, value: amount)
              in supply.phrases.entries)
            ListTile(
              title: Text('«$phrase»'),
              trailing: Text(
                withUnit(amount, supply.unit),
                style: theme.textTheme.bodyLarge,
              ),
            ),
        ],
      ),
    ];
  }
}
