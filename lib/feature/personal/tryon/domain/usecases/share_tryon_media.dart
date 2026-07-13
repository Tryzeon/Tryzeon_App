import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_media_repository.dart';
import 'package:typed_result/typed_result.dart';

/// Shares a finished try-on result.
class ShareTryonMedia {
  ShareTryonMedia({required final TryOnMediaRepository mediaRepository})
    : _mediaRepository = mediaRepository;

  final TryOnMediaRepository _mediaRepository;

  Future<Result<void, Failure>> call(final TryonResult result) {
    return _mediaRepository.share(result);
  }
}
