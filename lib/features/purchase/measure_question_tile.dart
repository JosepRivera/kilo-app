import 'package:material_ui/material_ui.dart';

import '../../core/app_name.dart';
import '../../core/formatters.dart';
import '../../core/widgets/amount_field.dart';
import '../../core/widgets/supply_icon.dart';
import 'purchase_line_draft.dart';

class MeasureQuestionTile extends StatefulWidget {
  const MeasureQuestionTile({
    super.key,
    required this.line,
    required this.onAnswer,
  });

  final PurchaseLineDraft line;
  final ValueChanged<double> onAnswer;

  @override
  State<MeasureQuestionTile> createState() => _MeasureQuestionTileState();
}

class _MeasureQuestionTileState extends State<MeasureQuestionTile> {
  double? _amount;

  void _submit() {
    final amount = _amount;
    if (amount != null && amount > 0) widget.onAnswer(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final line = widget.line;
    final supply = line.supply!;
    final question =
        '${howMany(supply.unit)} es «${line.phrase}» de ${line.spoken}?';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SupplyIcon(icon: supply.icon, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(supply.name, style: theme.textTheme.titleMedium),
                Text(question),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: AmountField(
                        label: question,
                        showLabel: false,
                        value: _amount,
                        suffix: supply.unit,
                        onChanged: (value) => setState(() => _amount = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: (_amount ?? 0) > 0 ? _submit : null,
                      child: const Text('Listo'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$appName lo recordará para la próxima vez.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
