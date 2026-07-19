import 'dart:convert';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_image_source.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_media_repository.dart';
import 'package:typed_result/typed_result.dart';

/// Resolves the avatar source for a try-on: a custom gallery avatar wins
/// (downloaded and inlined as base64); otherwise the stored profile avatar path
/// (which the backend fetches directly).
///
/// Callers guarantee at least one reference is present — the "no avatar" prompt
/// is a UI precondition handled before this runs — so the empty fallback here is
/// defensive only.
class ResolveTryonAvatar {
  ResolveTryonAvatar({required final TryonMediaRepository mediaRepository})
    : _mediaRepository = mediaRepository;

  final TryonMediaRepository _mediaRepository;

  Future<Result<TryonImageSource, Failure>> call({
    final String? customAvatarUrl,
    final String? profileAvatarPath,
  }) async {
    if (customAvatarUrl != null && customAvatarUrl.isNotEmpty) {
      final bytesResult = await _mediaRepository.loadImageBytes(customAvatarUrl);
      if (bytesResult.isFailure) {
        return Err(bytesResult.getError()!);
      }
      return Ok(TryonImageSource.base64(base64Encode(bytesResult.get()!)));
    }

    if (profileAvatarPath != null && profileAvatarPath.isNotEmpty) {
      return Ok(TryonImageSource.path(profileAvatarPath));
    }

    return const Err(ValidationFailure('No avatar available for try-on'));
  }
}
