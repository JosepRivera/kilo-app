import 'dart:io';

import 'package:record/record.dart';

import 'voice_recorder.dart';

class DeviceVoiceRecorder implements VoiceRecorder {
  DeviceVoiceRecorder(this._recorder);

  static const _config = RecordConfig(
    encoder: AudioEncoder.aacLc,
    sampleRate: 16000,
    numChannels: 1,
  );

  final AudioRecorder _recorder;

  @override
  Future<bool> start() async {
    if (!await _recorder.hasPermission()) return false;
    final path =
        '${Directory.systemTemp.path}/dictado-'
        '${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(_config, path: path);
    return true;
  }

  @override
  Future<String?> stop() => _recorder.stop();

  @override
  Future<void> cancel() => _recorder.cancel();

  @override
  Future<void> dispose() => _recorder.dispose();
}
