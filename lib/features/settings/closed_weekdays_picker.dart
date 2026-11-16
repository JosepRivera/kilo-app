import 'package:material_ui/material_ui.dart';

import '../../core/formatters.dart';

class ClosedWeekdaysPicker extends StatelessWidget {
  const ClosedWeekdaysPicker({
    super.key,
    required this.closed,
    required this.onToggle,
  });

  final List<int> closed;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Días que no abres',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var weekday = 1; weekday <= 7; weekday++)
                FilterChip(
                  label: Text(weekdayShort[weekday - 1]),
                  tooltip: capitalize(weekdayLong[weekday - 1]),
                  selected: closed.contains(weekday),
                  onSelected: (_) => onToggle(weekday),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
