import 'dart:typed_data';

enum RecorderStartResult { started, permissionDenied }

abstract interface class AudioRecorderService {
  Future<RecorderStartResult> start();
  Future<({Uint8List? bytes, String mimeType})> stop();
  Future<void> cancel();
  String get mimeType;
}
