import 'package:material_ui/material_ui.dart';

import '../../core/app_name.dart';
import '../../core/formatters.dart';
import '../../core/theme/kilo_colors.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/supply_icon.dart';
import '../../data/models/supply.dart';
import '../../data/models/supply_detail.dart';
import '../supplies/supply_detail_view_model.dart';
import 'why_buy_term.dart';

class WhyBuySheet extends StatelessWidget {
  const WhyBuySheet({super.key, required this.viewModel});

  final SupplyDetailViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      builder: (context, scrollController) => AsyncView<SupplyDetail>(
        source: viewModel,
        builder: (context, detail) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.only(bottom: 24),
          children: _content(context, detail),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, SupplyDetail detail) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final supply = detail.supply;
    final recommendation = detail.recommendation;
    final unit = supply.unit;
    final toBuy = recommendation.toBuy;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 16, 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '¿Por qué ${withUnit(toBuy, unit)}?',
                style: theme.textTheme.titleLarge,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Listo'),
            ),
          ],
        ),
      ),
      SectionCard(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SupplyIcon(icon: supply.icon, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Hasta tu próxima compra se usarán unos '
                    '${withUnit(recommendation.demand, unit)}. $appName suma '
                    'un colchón por si acaso y resta lo que ya tienes.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      SectionCard(
        children: [
          ExpansionTile(
            shape: const Border(),
            title: Row(
              children: [
                const Expanded(child: Text('Se usarán')),
                Text(withUnit(recommendation.demand, unit)),
              ],
            ),
            subtitle: Text('Próximos ${recommendation.horizonDays} días'),
            children: [
              for (final day in detail.week.take(recommendation.horizonDays))
                ListTile(
                  dense: true,
                  title: Text(capitalize(weekdayLong[day.day.weekday - 1])),
                  trailing: Text(
                    day.amount > 0 ? withUnit(day.amount, unit) : 'cerrado',
                  ),
                ),
            ],
          ),
          WhyBuyTerm(
            title: 'Colchón por si acaso',
            detail:
                '$appName suele fallar por unos '
                '${withUnit(recommendation.typicalError, unit)} al día',
            value: '+ ${withUnit(recommendation.buffer, unit)}',
          ),
          WhyBuyTerm(
            title: 'Ya tienes',
            value: '− ${withUnit(recommendation.onHand, unit)}',
          ),
          if (supply.learning)
            ListTile(
              leading: Icon(Icons.school_outlined, color: muted),
              title: Text(
                '$appName aún aprende: lleva ${supply.realDays} de '
                '${Supply.learningDays} días de datos reales de '
                '${supply.name.toLowerCase()}. Mientras tanto se apoya en tu '
                'gasto mensual declarado.',
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            ),
        ],
      ),
      SectionCard(
        children: [
          WhyBuyTerm(
            title: 'Comprar',
            detail: toBuy > 0 ? 'Redondeado para el mercado' : null,
            value: toBuy > 0 ? withUnit(toBuy, unit) : 'nada',
            emphasis: KiloColors.of(context).accent,
          ),
        ],
      ),
    ];
  }
}
