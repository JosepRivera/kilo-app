import 'package:material_ui/material_ui.dart';

class StepperRow extends StatelessWidget {
  const StepperRow({
    super.key,
    required this.label,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          IconButton(
            onPressed: onDecrement,
            tooltip: 'Menos',
            icon: const Icon(Icons.remove_circle_outline),
          ),
          IconButton(
            onPressed: onIncrement,
            tooltip: 'Más',
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
