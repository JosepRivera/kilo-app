import 'package:material_ui/material_ui.dart';

import '../../core/formatters.dart';
import '../../core/theme/kilo_colors.dart';
import '../../core/widgets/review_notice.dart';
import '../../core/widgets/supply_icon.dart';
import 'line_problem.dart';
import 'price_flag.dart';
import 'purchase_line_draft.dart';

class PurchaseLineTile extends StatelessWidget {
  const PurchaseLineTile({
    super.key,
    required this.line,
    required this.problem,
    required this.priceFlag,
    required this.onEdit,
    required this.onConfirmPrice,
    required this.onRemove,
  });

  final PurchaseLineDraft line;
  final LineProblem? problem;
  final PriceFlag? priceFlag;
  final VoidCallback onEdit;
  final VoidCallback onConfirmPrice;
  final VoidCallback onRemove;

  String _summary() {
    final supply = line.supply!;
    final quantity = line.quantity;
    final cost = line.cost;
    final expiresOn = line.expiresOn;
    return [
      if (quantity != null) withUnit(quantity, supply.unit),
      if (cost != null) money(cost),
      if (expiresOn != null) 'vence ${shortDate(expiresOn)}',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alert = KiloColors.of(context).alert;
    final supply = line.supply!;
    final flag = priceFlag;
    final problem = this.problem;
    final missing = problem != null && problem != LineProblem.price;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Dismissible(
          key: ValueKey('line-${line.id}'),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => onRemove(),
          background: ColoredBox(
            color: alert,
            child: const Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: 24),
                child: Icon(Icons.delete_outline, color: Colors.white),
              ),
            ),
          ),
          child: ListTile(
            onTap: onEdit,
            leading: SupplyIcon(icon: supply.icon, size: 36),
            title: Text(supply.name, style: theme.textTheme.titleMedium),
            subtitle: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: _summary()),
                  if (missing)
                    TextSpan(
                      text: _summary().isEmpty
                          ? problem.message
                          : ' · ${problem.message}',
                      style: TextStyle(color: alert),
                    ),
                ],
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
        if (flag != null)
          ReviewNotice(
            message:
                '${capitalize(supply.name.toLowerCase())} salió a '
                '${money(flag.unitPrice)} por ${unitLabel(supply.unit, 1)}; '
                'normalmente la pagas a ${money(flag.usual)}. ¿Es correcto?',
            actions: [
              TextButton(
                onPressed: onConfirmPrice,
                child: const Text('Sí, es correcto'),
              ),
              FilledButton.tonal(
                onPressed: onEdit,
                child: const Text('Corregir'),
              ),
            ],
          ),
      ],
    );
  }
}
