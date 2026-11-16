import 'package:flutter_test/flutter_test.dart';
import 'package:kilo_app/core/api_exception.dart';
import 'package:kilo_app/data/models/voice_draft.dart';
import 'package:kilo_app/data/models/voice_kind.dart';
import 'package:kilo_app/features/dictation/dictation_phase.dart';
import 'package:kilo_app/features/dictation/dictation_view_model.dart';

import '../support/fake_voice_recorder.dart';
import '../support/fake_voice_repository.dart';

void main() {
  const draft = VoiceDraft(transcript: 'quedan tres kilos de pollo', items: []);
  late FakeVoiceRepository voice;
  late FakeVoiceRecorder recorder;

  DictationViewModel build({bool granted = true}) {
    voice = FakeVoiceRepository();
    recorder = FakeVoiceRecorder(granted: granted);
    return DictationViewModel(
      voice: voice,
      recorder: recorder,
      initialKind: VoiceKind.close,
      clock: () => DateTime(2026, 11, 16, 21),
    );
  }

  test('records and sends the audio with the chosen kind', () async {
    final viewModel = build();
    await viewModel.start();
    expect(viewModel.phase, DictationPhase.recording);
    expect(viewModel.startedAt, DateTime(2026, 11, 16, 21));
    viewModel.selectKind(VoiceKind.purchase);
    voice.results.add(draft);
    expect(await viewModel.finish(), same(draft));
    expect(voice.calls.single, (VoiceKind.purchase, '/tmp/audio.m4a'));
  });

  test('a denied microphone leaves only manual entry', () async {
    final viewModel = build(granted: false);
    await viewModel.start();
    expect(viewModel.phase, DictationPhase.denied);
    expect(await viewModel.finish(), isNull);
    expect(voice.calls, isEmpty);
  });

  test('502 can be retried with the same recording', () async {
    final viewModel = build();
    await viewModel.start();
    voice.results.addAll([
      const ApiException(
        502,
        'No se pudo procesar el dictado, inténtalo otra vez',
      ),
      draft,
    ]);
    expect(await viewModel.finish(), isNull);
    expect(viewModel.phase, DictationPhase.failed);
    expect(viewModel.canRetry, isTrue);
    expect(await viewModel.retry(), same(draft));
    expect(voice.calls, hasLength(2));
    expect(recorder.starts, 1);
  });

  test('503 and 422 show the server text and record again', () async {
    final viewModel = build();
    await viewModel.start();
    voice.results.add(
      const ApiException(503, 'El dictado por voz no está configurado'),
    );
    await viewModel.finish();
    expect(viewModel.error, 'El dictado por voz no está configurado');
    expect(viewModel.canRetry, isFalse);
    await viewModel.retry();
    expect(recorder.starts, 2);
    expect(viewModel.phase, DictationPhase.recording);
  });

  test('cancel discards the recording and dispose releases it', () async {
    final viewModel = build();
    await viewModel.start();
    await viewModel.cancel();
    expect(recorder.cancelled, isTrue);
    viewModel.dispose();
    expect(recorder.disposed, isTrue);
  });
}
