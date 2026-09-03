import 'dart:io';
import 'dart:typed_data';

abstract class CacheService {
  Future<File> saveImage(final Uint8List bytes, final String filePath);

  Future<File?> getImage(final String filePath, {final String? downloadUrl});

  Future<void> deleteImage(final String filePath);

  Future<void> deleteImages(final List<String> filePaths);

  Future<void> clearCache();
}
