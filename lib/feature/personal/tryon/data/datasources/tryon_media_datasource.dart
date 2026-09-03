import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';

/// Throws on failure — the repository maps exceptions to [Failure]s and owns
/// temp-file cleanup.
class TryonMediaDataSource {
  TryonMediaDataSource({final BaseCacheManager? cacheManager, final Dio? dio})
    : _cacheManager = cacheManager ?? DefaultCacheManager(),
      _dio = dio ?? Dio();

  final BaseCacheManager _cacheManager;
  final Dio _dio;

  Future<Uint8List> downloadImageBytes(final String url) async {
    final file = await _cacheManager.getSingleFile(url);
    return file.readAsBytes();
  }

  /// The caller owns cleanup via [deleteTempFile].
  Future<String> downloadToTempFile(final String url, final TryonMode type) async {
    final tempDir = await getTemporaryDirectory();
    final path =
        '${tempDir.path}/tryon_${DateTime.now().millisecondsSinceEpoch}'
        '.${_extension(type)}';
    await _dio.download(url, path);
    return path;
  }

  Future<void> saveToGallery(final String path, final TryonMode type) async {
    switch (type) {
      case TryonMode.image:
        await Gal.putImage(path);
      case TryonMode.video:
        await Gal.putVideo(path);
    }
  }

  Future<void> shareFile(final String path, final TryonMode type) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path, mimeType: _mimeType(type))]),
    );
  }

  Future<void> deleteTempFile(final String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  String _extension(final TryonMode type) => type == TryonMode.video ? 'mp4' : 'jpg';

  String _mimeType(final TryonMode type) =>
      type == TryonMode.video ? 'video/mp4' : 'image/jpeg';
}
