import 'dart:typed_data';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:typed_result/typed_result.dart';

/// Persists and shares finished try-on media (images/videos) through one
/// symmetric pipeline, so callers never touch raw bytes or temp files.
abstract class TryonMediaRepository {
  /// Loads image bytes (cached) for [url] — used to build a base64 try-on
  /// source from a remote custom avatar.
  Future<Result<Uint8List, Failure>> loadImageBytes(final String url);

  /// Saves a finished try-on [result] to the device gallery.
  Future<Result<void, Failure>> saveToGallery(final TryonResult result);

  /// Shares a finished try-on [result].
  Future<Result<void, Failure>> share(final TryonResult result);
}
