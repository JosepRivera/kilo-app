import 'package:kilo_app/data/recorder/voice_recorder.dart';

class FakeVoiceRecorder implements VoiceRecorder {
  FakeVoiceRecorder({this.granted = true, this.path = '/tmp/audio.m4a'});

  final bool granted;
  final String? path;
  int starts = 0;
  bool cancelled = false;
  bool disposed = false;

  @override
  Future<bool> start() async {
    starts++;
    return granted;
  }

  @override
  Future<String?> stop() async => path;

  @override
  Future<void> cancel() async => cancelled = true;

  @override
  Future<void> dispose() async => disposed = true;
}
