import 'dart:convert';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_media_repository.dart';
import 'package:typed_result/typed_result.dart';

/// [url] is required: "there is nothing to send" is a question only the avatar
/// flow asks, and it is answered there rather than folded in here as a nullable
/// every caller then has to reason about.
class LoadImageAsBase64 {
  LoadImageAsBase64({required final TryonMediaRepository mediaRepository})
    : _mediaRepository = mediaRepository;

  final TryonMediaRepository _mediaRepository;

  Future<Result<String, Failure>> call(final String url) async {
    final bytesResult = await _mediaRepository.loadImageBytes(url);
    if (bytesResult.isFailure) {
      return Err(bytesResult.getError()!);
    }
    return Ok(base64Encode(bytesResult.get()!));
  }
}
