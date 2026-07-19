import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_image_source.dart';

part 'tryon_garment.freezed.dart';

@freezed
sealed class TryonGarment with _$TryonGarment {
  const factory TryonGarment({
    required final List<TryonImageSource> images,
    final String? detail,
  }) = _TryonGarment;
}
