import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_garment.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_image_source.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';

part 'tryon_params.freezed.dart';

@freezed
sealed class TryOnParams with _$TryOnParams {
  const factory TryOnParams({
    required final String requestId,
    required final TryOnImageSource avatar,
    required final List<TryOnGarment> garments,
    required final TryOnMode mode,
    final String? scenePrompt,
    final String? transitionPrompt,
  }) = _TryOnParams;
}
