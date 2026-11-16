import 'package:material_ui/material_ui.dart';

import '../../core/formatters.dart';
import '../../data/models/recent_day.dart';
import '../../data/models/recent_day_kind.dart';

class RecentDayTile extends StatelessWidget {
  const RecentDayTile({super.key, required this.day, required this.unit});

  final RecentDay day;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final amount = withUnit(day.amount, unit);
    final (text, color) = switch (day.kind) {
      RecentDayKind.real => (amount, scheme.onSurface),
      RecentDayKind.estimated => (
        '~$amount · estimado',
        scheme.onSurfaceVariant,
      ),
      RecentDayKind.closed => ('cerrado', scheme.onSurfaceVariant),
      RecentDayKind.missing => ('sin registro', scheme.outline),
    };
    return ListTile(
      title: Text(weekdayAndDay(day.day)),
      trailing: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: color),
      ),
    );
  }
}
