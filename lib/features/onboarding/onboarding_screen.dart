import 'package:material_ui/material_ui.dart';

import '../../core/app_name.dart';
import '../../core/theme/kilo_colors.dart';
import 'onboarding_view_model.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.viewModel});

  final OnboardingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Bienvenido a $appName',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cada mañana te dice qué comprar y cuánto, con lo que '
                    'registras al cerrar.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onChanged: viewModel.setName,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de tu restaurante',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    textInputAction: TextInputAction.done,
                    onChanged: viewModel.setInviteCode,
                    onSubmitted: (_) => viewModel.submit(),
                    decoration: const InputDecoration(
                      labelText: 'Código de invitación (opcional)',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ListenableBuilder(
                    listenable: viewModel,
                    builder: (context, _) {
                      final error = viewModel.error;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                error,
                                style: TextStyle(
                                  color: KiloColors.of(context).alert,
                                ),
                              ),
                            ),
                          FilledButton(
                            onPressed: viewModel.canSubmit
                                ? viewModel.submit
                                : null,
                            child: Text(
                              viewModel.isSubmitting
                                  ? 'Creando tu restaurante…'
                                  : 'Empezar',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
