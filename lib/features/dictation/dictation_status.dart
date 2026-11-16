import 'package:material_ui/material_ui.dart';

import '../../core/theme/kilo_colors.dart';
import '../../data/models/voice_kind.dart';
import 'dictation_phase.dart';
import 'dictation_view_model.dart';
import 'elapsed_label.dart';

class DictationStatus extends StatelessWidget {
  const DictationStatus({super.key, required this.viewModel});

  final DictationViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = KiloColors.of(context);
    final title = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final muted = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Semantics(
      liveRegion: true,
      child: switch (viewModel.phase) {
        DictationPhase.sending => Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Procesando…', style: title),
          ],
        ),
        DictationPhase.recording => Column(
          children: [
            ExcludeSemantics(
              child: Icon(Icons.graphic_eq, size: 48, color: colors.accent),
            ),
            const SizedBox(height: 8),
            ElapsedLabel(since: viewModel.startedAt ?? DateTime.now()),
            const SizedBox(height: 8),
            Text('Te escucho', style: title),
            const SizedBox(height: 4),
            Text(
              viewModel.kind == VoiceKind.close
                  ? 'Di cuánto queda de cada insumo.'
                  : 'Di qué compraste, cuánto y a qué precio.',
              style: muted,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        DictationPhase.denied => Column(
          children: [
            Icon(Icons.mic_off, size: 48, color: colors.alert),
            const SizedBox(height: 8),
            Text('Sin acceso al micrófono', style: title),
            const SizedBox(height: 4),
            Text(
              'Actívalo en los ajustes del teléfono o registra a mano.',
              style: muted,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        DictationPhase.failed => Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.alert),
            const SizedBox(height: 8),
            Text(
              viewModel.error ?? '',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        DictationPhase.idle => const SizedBox.shrink(),
      },
    );
  }
}
