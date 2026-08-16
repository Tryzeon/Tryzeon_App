import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_image_source.dart';

part 'tryon_garment.freezed.dart';

/// A garment to try on: either the user's own image sources, or a catalog
/// product by id (the backend resolves its image and prompt detail).
@freezed
sealed class TryonGarment with _$TryonGarment {
  const factory TryonGarment.images({required final List<TryonImageSource> images}) =
      TryonGarmentImages;

  /// [sizeId] names which published size is being worn, so the backend can
  /// describe how that size sits on this shopper. Null when there is no
  /// recommendation to make — most often because the shopper has recorded no
  /// body measurements.
  const factory TryonGarment.product({
    required final String productId,
    final String? sizeId,
  }) = TryonGarmentProduct;
}
