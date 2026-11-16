import '../json.dart';
import 'voice_item.dart';

class VoiceDraft {
  const VoiceDraft({required this.transcript, required this.items});

  factory VoiceDraft.fromJson(Json json) => VoiceDraft(
    transcript: json['transcript']! as String,
    items: decodeList(json['items'], VoiceItem.fromJson),
  );

  final String transcript;
  final List<VoiceItem> items;
}
