abstract interface class VoiceRecorder {
  Future<bool> start();

  Future<String?> stop();

  Future<void> cancel();

  Future<void> dispose();
}
