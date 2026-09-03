import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_engine.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_garment.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';

part 'tryon_request.freezed.dart';

@freezed
sealed class TryonRequest with _$TryonRequest {
  /// A null [avatarBase64] means the backend uses the model photo on the user's
  /// profile, which is the only authoritative copy of it.
  const factory TryonRequest.generate({
    required final String requestId,
    required final List<TryonGarment> garments,
    required final TryonMode mode,
    required final TryonEngine engine,
    final String? avatarBase64,
    final String? scenePrompt,
    final String? stylingPrompt,
    final String? transitionPrompt,
  }) = TryonGenerateRequest;

  /// No mode field because video is the only thing a finished picture can
  /// become, and no scene or styling prompt because both are already settled in
  /// the picture.
  const factory TryonRequest.animate({
    required final String requestId,
    required final String baseImageBase64,
    required final TryonEngine engine,
    final String? transitionPrompt,
  }) = TryonAnimateRequest;

  const TryonRequest._();

  TryonMode get mode => switch (this) {
    TryonGenerateRequest(:final mode) => mode,
    TryonAnimateRequest() => TryonMode.video,
  };
}
