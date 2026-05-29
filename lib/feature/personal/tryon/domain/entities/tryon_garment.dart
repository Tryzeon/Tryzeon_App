import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_image_source.dart';

part 'tryon_garment.freezed.dart';

@freezed
sealed class TryOnGarment with _$TryOnGarment {
  const factory TryOnGarment({
    required final List<TryOnImageSource> images,
  }) = _TryOnGarment;
}
