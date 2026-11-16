import '../../core/api_client.dart';
import '../json.dart';
import '../models/voice_draft.dart';
import '../models/voice_kind.dart';

class VoiceRepository {
  const VoiceRepository(this._api);

  final ApiClient _api;

  Future<VoiceDraft> transcribe({
    required VoiceKind kind,
    required String audioPath,
  }) async {
    final json = await _api.postFile(
      '/voice',
      fields: {'kind': kind.name},
      fileField: 'audio',
      filePath: audioPath,
    );
    return VoiceDraft.fromJson(json! as Json);
  }
}
