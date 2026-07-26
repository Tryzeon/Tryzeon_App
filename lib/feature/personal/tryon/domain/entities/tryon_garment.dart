import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_image_source.dart';

part 'tryon_garment.freezed.dart';

/// A garment to try on: either the user's own image sources, or a catalog
/// product by id (the backend resolves its image and prompt detail).
@freezed
sealed class TryonGarment with _$TryonGarment {
  const factory TryonGarment.images({required final List<TryonImageSource> images}) =
      TryonGarmentImages;

  const factory TryonGarment.product({required final String productId}) =
      TryonGarmentProduct;
}
