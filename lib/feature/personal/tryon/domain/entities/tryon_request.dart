import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_garment.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';

part 'tryon_request.freezed.dart';

/// A try-on request. [avatarBase64] is an override for the gallery's custom
/// avatar; when null the backend uses the model photo on the user's profile,
/// which is the only authoritative copy of it.
@freezed
sealed class TryonRequest with _$TryonRequest {
  const factory TryonRequest({
    required final String requestId,
    required final List<TryonGarment> garments,
    required final TryonMode mode,
    final String? avatarBase64,
    final String? scenePrompt,
    final String? transitionPrompt,
  }) = _TryonRequest;
}
