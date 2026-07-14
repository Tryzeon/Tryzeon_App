import 'dart:io';
import 'dart:typed_data';

import 'package:image_background_remover/image_background_remover.dart' as bg;
import 'package:tryzeon/core/utils/app_logger.dart';

import '../../domain/services/background_remover.dart';

class BackgroundRemoverImpl implements BackgroundRemover {
  BackgroundRemoverImpl();

  Future<void>? _initFuture;

  Future<void> _ensureInit() async {
    final existing = _initFuture;
    if (existing != null) return existing;
    final future = bg.BackgroundRemover.instance.initializeOrt();
    _initFuture = future;
    try {
      await future;
    } catch (e, st) {
      // Don't cache a failed init — allow the next call to retry.
      AppLogger.warning('Background remover init failed; will retry next call', e, st);
      _initFuture = null;
      rethrow;
    }
  }

  @override
  Future<Uint8List?> remove(final File image) async {
    final bytes = await image.readAsBytes();
    await _ensureInit();
    return bg.BackgroundRemover.instance.removeBgBytes(bytes);
  }
}
