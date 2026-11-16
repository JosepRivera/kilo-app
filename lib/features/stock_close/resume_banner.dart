import 'package:material_ui/material_ui.dart';

class ResumeBanner extends StatelessWidget {
  const ResumeBanner({super.key, required this.onRestart});

  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.history),
      title: const Text('Retomaste tu cierre sin terminar'),
      trailing: TextButton(
        onPressed: onRestart,
        child: const Text('Empezar de nuevo'),
      ),
    );
  }
}
