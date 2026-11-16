import 'package:material_ui/material_ui.dart';

class NoConsumptionDialog extends StatelessWidget {
  const NoConsumptionDialog({super.key});

  static Future<bool> confirm(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => const NoConsumptionDialog(),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return AlertDialog(
      title: const Text('¿Hoy no hubo consumo?'),
      content: const Text(
        'El día queda en cero y cuenta como dato real, no como olvido.',
      ),
      actions: [
        TextButton(
          onPressed: () => navigator.pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => navigator.pop(true),
          child: const Text('Marcar sin consumo'),
        ),
      ],
    );
  }
}
