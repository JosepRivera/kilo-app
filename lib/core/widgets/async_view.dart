import 'package:material_ui/material_ui.dart';

import '../loadable.dart';
import 'empty_state.dart';

class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.source, required this.builder});

  final Loadable<T> source;
  final Widget Function(BuildContext context, T value) builder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: source,
      builder: (context, _) {
        final value = source.value;
        if (value != null) return builder(context, value);
        final error = source.error;
        if (error == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Center(
          child: SingleChildScrollView(
            child: EmptyState(
              icon: Icons.cloud_off,
              title: 'No se pudo cargar',
              message: error,
              actionLabel: 'Reintentar',
              onAction: source.load,
            ),
          ),
        );
      },
    );
  }
}
