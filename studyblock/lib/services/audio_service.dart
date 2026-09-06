import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Thin wrapper around the `record` package for voice-memo recording.
///
/// This is a premium-only feature in the UI (see PremiumLockCard usage in
/// TimerScreen). Recordings are saved as .m4a files in the app's own
/// documents directory and referenced by path from TaskBlock.voiceNotePath.
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Stream<Amplitude> amplitudeStream(Duration interval) =>
      _recorder.onAmplitudeChanged(interval);

  Future<void> startRecording(String blockId) async {
    if (!await hasPermission()) {
      throw Exception('Microphone permission denied');
    }
    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/voice_note_${blockId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    _currentPath = path;
  }

  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    return path ?? _currentPath;
  }

  Future<bool> isRecording() => _recorder.isRecording();

  Future<void> dispose() async {
    await _recorder.dispose();
  }

  bool fileExists(String? path) {
    if (path == null) return false;
    return File(path).existsSync();
  }
}
