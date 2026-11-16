import 'package:material_ui/material_ui.dart';

import '../../core/formatters.dart';
import '../../core/theme/kilo_colors.dart';
import '../../core/widgets/amount_field.dart';
import '../../core/widgets/review_notice.dart';
import '../../core/widgets/supply_icon.dart';
import 'close_entry.dart';
import 'close_flag.dart';
import 'close_suggestion_notice.dart';

class CloseEntryTile extends StatefulWidget {
  const CloseEntryTile({
    super.key,
    required this.entry,
    required this.flag,
    required this.onChanged,
    required this.onConfirmFlag,
    required this.onAcceptSuggestion,
    required this.onKeepHeard,
  });

  final CloseEntry entry;
  final CloseFlag? flag;
  final ValueChanged<double?> onChanged;
  final VoidCallback onConfirmFlag;
  final VoidCallback onAcceptSuggestion;
  final VoidCallback onKeepHeard;

  @override
  State<CloseEntryTile> createState() => _CloseEntryTileState();
}

class _CloseEntryTileState extends State<CloseEntryTile> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final supply = entry.supply;
    final flag = widget.flag;
    final suggested = entry.suggested;
    final flagged = flag != null && !entry.flagConfirmed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              SupplyIcon(icon: supply.icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  supply.name,
                  style: TextStyle(
                    color: flagged ? KiloColors.of(context).alert : null,
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: AmountField(
                  label: 'Queda de ${supply.name}',
                  showLabel: false,
                  focusNode: _focus,
                  value: entry.remaining,
                  suffix: supply.unit,
                  onChanged: widget.onChanged,
                ),
              ),
            ],
          ),
        ),
        if (flagged)
          ReviewNotice(
            message:
                'Según lo que dictaste, hoy se usaron '
                '${withUnit(flag.consumed, supply.unit)} de '
                '${supply.name.toLowerCase()}; normalmente son unos '
                '${withUnit(flag.usual, supply.unit)}. ¿Es correcto?',
            actions: [
              TextButton(
                onPressed: widget.onConfirmFlag,
                child: const Text('Sí, es correcto'),
              ),
              FilledButton.tonal(
                onPressed: () =>
                    _focus.focusInDirection(TraversalDirection.down),
                child: const Text('Corregir'),
              ),
            ],
          ),
        if (suggested != null)
          CloseSuggestionNotice(
            heard: entry.remaining,
            suggested: suggested,
            unit: supply.unit,
            onAccept: widget.onAcceptSuggestion,
            onKeep: widget.onKeepHeard,
          ),
      ],
    );
  }
}
