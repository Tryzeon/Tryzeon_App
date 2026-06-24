import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/products/domain/services/audio_recorder_service.dart';
import 'package:tryzeon/feature/store/products/presentation/hooks/use_product_size_manager.dart';
import 'package:tryzeon/feature/store/products/providers/store_products_providers.dart';

enum SizeVoiceStatus { idle, recording, uploading }

class SizeVoiceInput {
  const SizeVoiceInput({required this.status, required this.toggle});

  final SizeVoiceStatus status;
  final Future<void> Function() toggle;
}

const _maxRecordingDuration = Duration(seconds: 60);

SizeVoiceInput useSizeVoiceInput({
  required final WidgetRef ref,
  required final ProductSizeManager sizeManager,
  required final void Function(int addedCount) onApplied,
  required final void Function(String message) onError,
  required final VoidCallback onPermissionDenied,
}) {
  final status = useState(SizeVoiceStatus.idle);
  final autoStopTimer = useRef<Timer?>(null);

  useEffect(
    () =>
        () => autoStopTimer.value?.cancel(),
    const [],
  );

  Future<void> stopAndParse(final AudioRecorderService recorder) async {
    autoStopTimer.value?.cancel();
    status.value = SizeVoiceStatus.uploading;
    try {
      final recording = await recorder.stop();
      final bytes = recording.bytes;
      if (bytes == null || bytes.isEmpty) {
        onError('沒有錄到聲音，請再試一次');
        return;
      }
      final parser = ref.read(sizeVoiceParserProvider);
      final parsed = await parser.parse(
        audioBytes: bytes,
        mimeType: recording.mimeType,
        currentUnit: sizeManager.selectedUnit,
      );
      if (parsed.isEmpty) {
        onError('沒有聽到尺寸資訊，請再試一次');
        return;
      }
      sizeManager.appendParsedSizes(parsed);
      onApplied(parsed.length);
    } catch (e, st) {
      AppLogger.error('Size voice parse failed', e, st);
      onError('語音解析失敗，請再試一次');
    } finally {
      status.value = SizeVoiceStatus.idle;
    }
  }

  Future<void> toggle() async {
    final recorder = ref.read(audioRecorderServiceProvider);

    if (status.value == SizeVoiceStatus.recording) {
      await stopAndParse(recorder);
      return;
    }
    if (status.value == SizeVoiceStatus.uploading) return;

    final result = await recorder.start();
    if (result == RecorderStartResult.permissionDenied) {
      onPermissionDenied();
      return;
    }
    status.value = SizeVoiceStatus.recording;
    autoStopTimer.value = Timer(_maxRecordingDuration, () {
      if (status.value == SizeVoiceStatus.recording) {
        stopAndParse(recorder);
      }
    });
  }

  return SizeVoiceInput(status: status.value, toggle: toggle);
}
