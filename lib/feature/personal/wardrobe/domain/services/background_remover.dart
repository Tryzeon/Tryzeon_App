import 'dart:io';
import 'dart:typed_data';

abstract interface class BackgroundRemover {
  Future<Uint8List?> remove(final File image);
}
