import 'package:kilo_app/core/api_exception.dart';
import 'package:kilo_app/data/models/voice_draft.dart';
import 'package:kilo_app/data/models/voice_kind.dart';
import 'package:kilo_app/data/repositories/voice_repository.dart';

class FakeVoiceRepository implements VoiceRepository {
  final List<(VoiceKind, String)> calls = [];
  final List<Object> results = [];

  @override
  Future<VoiceDraft> transcribe({
    required VoiceKind kind,
    required String audioPath,
  }) async {
    calls.add((kind, audioPath));
    final result = results.removeAt(0);
    if (result is ApiException) throw result;
    return result as VoiceDraft;
  }
}
