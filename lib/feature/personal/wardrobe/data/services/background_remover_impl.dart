import 'dart:io';
import 'dart:typed_data';

import 'package:image_background_remover/image_background_remover.dart' as bg;

import '../../domain/services/background_remover.dart';

class BackgroundRemoverImpl implements BackgroundRemover {
  BackgroundRemoverImpl();

  Future<void>? _initFuture;

  Future<void> _ensureInit() {
    return _initFuture ??= bg.BackgroundRemover.instance.initializeOrt();
  }

  @override
  Future<Uint8List?> remove(final File image) async {
    final (_, bytes) = await (_ensureInit(), image.readAsBytes()).wait;
    return bg.BackgroundRemover.instance.removeBgBytes(bytes);
  }
}
