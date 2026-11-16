import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../data/models/voice_draft.dart';
import '../../data/models/voice_kind.dart';
import 'dictation_phase.dart';
import 'dictation_result.dart';
import 'dictation_status.dart';
import 'dictation_view_model.dart';

class DictationSheet extends StatefulWidget {
  const DictationSheet({super.key, required this.viewModel});

  final DictationViewModel viewModel;

  @override
  State<DictationSheet> createState() => _DictationSheetState();
}

class _DictationSheetState extends State<DictationSheet> {
  DictationViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    unawaited(_viewModel.start());
  }

  void _complete(VoiceDraft? draft) {
    if (draft == null || !mounted) return;
    Navigator.of(context)
        .pop(DictationResult(kind: _viewModel.kind, draft: draft));
  }

  Future<void> _manual() async {
    await _viewModel.cancel();
    if (!mounted) return;
    Navigator.of(context).pop(DictationResult(kind: _viewModel.kind));
  }

  Future<void> _close() async {
    await _viewModel.cancel();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final phase = _viewModel.phase;
            final busy = _viewModel.isBusy;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<VoiceKind>(
                        showSelectedIcon: false,
                        segments: [
                          for (final kind in VoiceKind.values)
                            ButtonSegment(value: kind, label: Text(kind.title)),
                        ],
                        selected: {_viewModel.kind},
                        onSelectionChanged: busy
                            ? null
                            : (kinds) => _viewModel.selectKind(kinds.first),
                      ),
                    ),
                    IconButton(
                      onPressed: busy ? null : _close,
                      tooltip: 'Cancelar',
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 160),
                  child: Center(child: DictationStatus(viewModel: _viewModel)),
                ),
                const SizedBox(height: 24),
                if (phase == DictationPhase.recording)
                  FilledButton(
                    onPressed: () async => _complete(await _viewModel.finish()),
                    child: const Text('Listo'),
                  )
                else if (phase == DictationPhase.failed ||
                    phase == DictationPhase.denied)
                  FilledButton.tonal(
                    onPressed: () async => _complete(await _viewModel.retry()),
                    child: Text(
                      _viewModel.canRetry ? 'Reintentar' : 'Grabar otra vez',
                    ),
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: busy ? null : _manual,
                  child: const Text('Registrar a mano'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
