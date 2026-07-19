import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_garment.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_image_source.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';

part 'tryon_request.freezed.dart';

/// A fully-specified try-on request: garments plus the *resolved* [avatar]
/// source. The avatar is resolved upstream (see `ResolveTryonAvatar`) so every
/// field here is ready for the backend — no unresolved candidate references
/// leak into the repository or the wire body.
@freezed
sealed class TryonRequest with _$TryonRequest {
  const factory TryonRequest({
    required final String requestId,
    required final TryonImageSource avatar,
    required final List<TryonGarment> garments,
    required final TryonMode mode,
    final String? scenePrompt,
    final String? transitionPrompt,
  }) = _TryonRequest;
}
