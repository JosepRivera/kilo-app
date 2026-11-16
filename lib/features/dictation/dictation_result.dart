import '../../data/models/voice_draft.dart';
import '../../data/models/voice_kind.dart';

class DictationResult {
  const DictationResult({required this.kind, this.draft});

  final VoiceKind kind;
  final VoiceDraft? draft;
}
