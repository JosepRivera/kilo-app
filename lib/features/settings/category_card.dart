import 'package:material_ui/material_ui.dart';

import '../../core/formatters.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/stepper_row.dart';
import '../../data/models/supply_category.dart';
import 'settings_view_model.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.onInterval,
    required this.onEditSpend,
  });

  final SupplyCategory category;
  final ValueChanged<int> onInterval;
  final VoidCallback onEditSpend;

  @override
  Widget build(BuildContext context) {
    final days = category.purchaseIntervalDays;
    return SectionCard(
      header: Text(category.name),
      children: [
        StepperRow(
          label: days == 1 ? 'Compras cada día' : 'Compras cada $days días',
          onDecrement: days > 1 ? () => onInterval(days - 1) : null,
          onIncrement: days < SettingsViewModel.maxPurchaseInterval
              ? () => onInterval(days + 1)
              : null,
        ),
        ListTile(
          title: const Text('Gasto al mes'),
          trailing: Text(
            soles(category.monthlySpend),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          onTap: onEditSpend,
        ),
      ],
    );
  }
}
