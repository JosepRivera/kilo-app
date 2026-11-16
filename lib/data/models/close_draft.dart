import '../json.dart';

class CloseDraft {
  const CloseDraft({
    required this.day,
    required this.remaining,
    required this.transcript,
  });

  factory CloseDraft.fromJson(Json json) => CloseDraft(
    day: json['day']! as String,
    remaining: {
      for (final MapEntry(:key, :value) in (json['remaining']! as Json).entries)
        key: decodeDouble(value),
    },
    transcript: json['transcript'] as String?,
  );

  final String day;
  final Map<String, double> remaining;
  final String? transcript;

  Json toJson() => {
    'day': day,
    'remaining': remaining,
    'transcript': transcript,
  };
}
