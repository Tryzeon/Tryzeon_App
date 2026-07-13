import 'dart:convert';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_image_source.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_media_repository.dart';
import 'package:typed_result/typed_result.dart';

/// Resolves the avatar source for a try-on request: a custom gallery avatar
/// wins (downloaded and inlined as base64); otherwise the stored profile avatar
/// path is used (the backend fetches it directly).
///
/// Returns `Ok(null)` when no avatar is available, and `Err` only when a custom
/// avatar was present but failed to load — letting the caller distinguish
/// "upload a photo first" from "loading failed, try again".
class PrepareTryonAvatarSource {
  PrepareTryonAvatarSource({required final TryOnMediaRepository mediaRepository})
    : _mediaRepository = mediaRepository;

  final TryOnMediaRepository _mediaRepository;

  Future<Result<TryOnImageSource?, Failure>> call({
    final String? customAvatarUrl,
    final String? profileAvatarPath,
  }) async {
    if (customAvatarUrl != null && customAvatarUrl.isNotEmpty) {
      final bytesResult = await _mediaRepository.loadImageBytes(customAvatarUrl);
      if (bytesResult.isFailure) {
        return Err(bytesResult.getError()!);
      }
      return Ok(TryOnImageSource.base64(base64Encode(bytesResult.get()!)));
    }

    if (profileAvatarPath != null && profileAvatarPath.isNotEmpty) {
      return Ok(TryOnImageSource.path(profileAvatarPath));
    }

    return const Ok(null);
  }
}
