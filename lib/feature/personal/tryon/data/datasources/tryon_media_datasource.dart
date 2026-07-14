import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';

/// Raw device-level media I/O for finished try-on results. Both images and
/// videos are handled through local temp files so save/share/watermark stay
/// symmetric across media types. Throws on failure — the repository maps
/// exceptions to [Failure]s and owns temp-file cleanup.
class TryOnMediaDataSource {
  TryOnMediaDataSource({final BaseCacheManager? cacheManager, final Dio? dio})
    : _cacheManager = cacheManager ?? DefaultCacheManager(),
      _dio = dio ?? Dio();

  final BaseCacheManager _cacheManager;
  final Dio _dio;

  /// Loads cached image bytes — used to inline a remote avatar as base64 for a
  /// try-on request (distinct from the save/share pipeline).
  Future<Uint8List> downloadImageBytes(final String url) async {
    final file = await _cacheManager.getSingleFile(url);
    return file.readAsBytes();
  }

  /// Downloads [url] into a temp file named for its media [type], returning the
  /// local path. The caller owns cleanup via [deleteTempFile].
  Future<String> downloadToTempFile(final String url, final TryOnMode type) async {
    final tempDir = await getTemporaryDirectory();
    final path =
        '${tempDir.path}/tryon_${DateTime.now().millisecondsSinceEpoch}'
        '.${_extension(type)}';
    await _dio.download(url, path);
    return path;
  }

  Future<void> saveToGallery(final String path, final TryOnMode type) async {
    switch (type) {
      case TryOnMode.image:
        await Gal.putImage(path);
      case TryOnMode.video:
        await Gal.putVideo(path);
    }
  }

  Future<void> shareFile(final String path, final TryOnMode type) async {
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

  String _extension(final TryOnMode type) => type == TryOnMode.video ? 'mp4' : 'jpg';

  String _mimeType(final TryOnMode type) =>
      type == TryOnMode.video ? 'video/mp4' : 'image/jpeg';
}
