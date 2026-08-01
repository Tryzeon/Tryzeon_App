import 'dart:convert';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_media_repository.dart';
import 'package:typed_result/typed_result.dart';

/// Loads the gallery's custom avatar as inline base64, or null when none is
/// selected — the backend then uses the profile's model photo.
class LoadCustomAvatar {
  LoadCustomAvatar({required final TryonMediaRepository mediaRepository})
    : _mediaRepository = mediaRepository;

  final TryonMediaRepository _mediaRepository;

  Future<Result<String?, Failure>> call(final String? customAvatarUrl) async {
    if (customAvatarUrl == null || customAvatarUrl.isEmpty) {
      return const Ok(null);
    }

    final bytesResult = await _mediaRepository.loadImageBytes(customAvatarUrl);
    if (bytesResult.isFailure) {
      return Err(bytesResult.getError()!);
    }
    return Ok(base64Encode(bytesResult.get()!));
  }
}
