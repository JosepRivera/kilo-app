import 'package:material_ui/material_ui.dart';

import 'close_exit_choice.dart';

class CloseExitDialog extends StatelessWidget {
  const CloseExitDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return AlertDialog(
      title: const Text('¿Qué quieres hacer con tu cierre?'),
      actions: [
        TextButton(
          onPressed: () => navigator.pop(CloseExitChoice.discard),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Descartar cierre'),
        ),
        TextButton(onPressed: navigator.pop, child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => navigator.pop(CloseExitChoice.keepDraft),
          child: const Text('Guardar borrador'),
        ),
      ],
    );
  }
}
