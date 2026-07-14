import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/products/domain/services/audio_recorder_service.dart';

class AudioRecorderServiceImpl implements AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _path;

  @override
  String get mimeType => 'audio/mp4';

  @override
  Future<RecorderStartResult> start() async {
    if (!await _recorder.hasPermission()) {
      return RecorderStartResult.permissionDenied;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/size_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    _path = path;
    return RecorderStartResult.started;
  }

  @override
  Future<({Uint8List? bytes, String mimeType})> stop() async {
    final path = await _recorder.stop();
    final target = path ?? _path;
    _path = null;
    if (target == null) return (bytes: null, mimeType: mimeType);
    final file = File(target);
    if (!await file.exists()) return (bytes: null, mimeType: mimeType);
    final bytes = await file.readAsBytes();
    try {
      await file.delete();
    } catch (e, st) {
      AppLogger.warning('Failed to delete temp recording file', e, st);
    }
    return (bytes: bytes, mimeType: mimeType);
  }

  @override
  Future<void> cancel() async {
    await _recorder.cancel();
    _path = null;
  }
}
