import 'dart:typed_data';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/tryon/data/datasources/tryon_media_datasource.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_media_repository.dart';
import 'package:typed_result/typed_result.dart';

class TryOnMediaRepositoryImpl implements TryOnMediaRepository {
  TryOnMediaRepositoryImpl({required final TryOnMediaDataSource dataSource})
    : _dataSource = dataSource;

  final TryOnMediaDataSource _dataSource;

  @override
  Future<Result<Uint8List, Failure>> loadImageBytes(final String url) async {
    try {
      return Ok(await _dataSource.downloadImageBytes(url));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load try-on image bytes', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> saveToGallery(final TryonResult result) {
    return _process(
      result,
      (final path) => _dataSource.saveToGallery(path, result.mode),
      onError: 'Failed to save try-on ${result.mode.name}',
    );
  }

  @override
  Future<Result<void, Failure>> share(final TryonResult result) {
    return _process(
      result,
      (final path) => _dataSource.shareFile(path, result.mode),
      onError: 'Failed to share try-on ${result.mode.name}',
    );
  }

  /// Symmetric pipeline for both media types: resolve URL → download → sink,
  /// always cleaning up the temp file afterwards.
  Future<Result<void, Failure>> _process(
    final TryonResult result,
    final Future<void> Function(String path) sink, {
    required final String onError,
  }) async {
    final url = result.mode == TryOnMode.video
        ? result.videoUrl
        : result.imageUrl;
    if (url == null || url.isEmpty) {
      return Err(ValidationFailure('${result.mode.name} URL is missing'));
    }

    String? tempPath;
    try {
      tempPath = await _dataSource.downloadToTempFile(url, result.mode);
      await sink(tempPath);
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error(onError, e, stackTrace);
      return Err(mapExceptionToFailure(e));
    } finally {
      if (tempPath != null) {
        await _dataSource.deleteTempFile(tempPath);
      }
    }
  }
}
