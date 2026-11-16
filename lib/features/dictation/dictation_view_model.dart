import 'package:flutter/foundation.dart';

import '../../core/api_exception.dart';
import '../../data/models/voice_draft.dart';
import '../../data/models/voice_kind.dart';
import '../../data/recorder/voice_recorder.dart';
import '../../data/repositories/voice_repository.dart';
import 'dictation_phase.dart';

class DictationViewModel extends ChangeNotifier {
  DictationViewModel({
    required this._voice,
    required this._recorder,
    required VoiceKind initialKind,
    this._clock = DateTime.now,
  }) : _kind = initialKind;

  static const _noAudio = 'No se grabó audio. Inténtalo otra vez.';

  final VoiceRepository _voice;
  final VoiceRecorder _recorder;
  final DateTime Function() _clock;
  VoiceKind _kind;
  DictationPhase _phase = DictationPhase.idle;
  DateTime? _startedAt;
  String? _audioPath;
  String? _error;
  bool _canRetry = false;
  bool _disposed = false;

  VoiceKind get kind => _kind;
  DictationPhase get phase => _phase;
  DateTime? get startedAt => _startedAt;
  String? get error => _error;
  bool get canRetry => _canRetry;
  bool get isBusy => _phase == DictationPhase.sending;

  void selectKind(VoiceKind kind) {
    if (isBusy) return;
    _kind = kind;
    notifyListeners();
  }

  Future<void> start() async {
    if (_phase == DictationPhase.recording || isBusy) return;
    _error = null;
    _canRetry = false;
    _audioPath = null;
    final granted = await _recorder.start();
    if (_disposed) return;
    _phase = granted ? DictationPhase.recording : DictationPhase.denied;
    _startedAt = granted ? _clock() : null;
    notifyListeners();
  }

  Future<VoiceDraft?> finish() async {
    if (_phase != DictationPhase.recording) return null;
    final path = await _recorder.stop();
    if (path == null) {
      _fail(_noAudio, retryable: false);
      return null;
    }
    _audioPath = path;
    return _send();
  }

  Future<VoiceDraft?> retry() =>
      _audioPath == null ? start().then((_) => null) : _send();

  Future<void> cancel() async {
    if (_phase == DictationPhase.recording) await _recorder.cancel();
    _phase = DictationPhase.idle;
  }

  Future<VoiceDraft?> _send() async {
    final path = _audioPath;
    if (path == null) return null;
    _phase = DictationPhase.sending;
    _error = null;
    notifyListeners();
    try {
      final draft = await _voice.transcribe(kind: _kind, audioPath: path);
      _phase = DictationPhase.idle;
      notifyListeners();
      return draft;
    } on ApiException catch (failure) {
      _fail(failure.message, retryable: failure.isRetryable);
      return null;
    }
  }

  void _fail(String message, {required bool retryable}) {
    _phase = DictationPhase.failed;
    _error = message;
    _canRetry = retryable;
    if (!retryable) _audioPath = null;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _recorder.dispose();
    super.dispose();
  }
}
