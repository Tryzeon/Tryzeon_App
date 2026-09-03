import 'package:freezed_annotation/freezed_annotation.dart';

part 'tryon_garment.freezed.dart';

/// A garment to try on: the user's own photos as inline bytes, a catalog
/// product by id, or one of their wardrobe items by id. The backend resolves
/// both reference kinds to an image and a prompt detail.
@freezed
sealed class TryonGarment with _$TryonGarment {
  /// Bytes and never a storage path: the backend accepts only inline images
  /// from a caller, because whether the caller may read a stored object is not
  /// a question the path can answer. Anything already stored is named by
  /// reference instead — see the two variants below.
  const factory TryonGarment.images({
    required final List<String> base64Images,
  }) = TryonGarmentImages;

  /// [sizeId] names which published size is being worn, so the backend can
  /// describe how that size sits on this shopper. Null when there is no
  /// recommendation to make — most often because the shopper has recorded no
  /// body measurements.
  const factory TryonGarment.product({
    required final String productId,
    final String? sizeId,
  }) = TryonGarmentProduct;

  /// A reference rather than the item's image path, so the backend can bind the
  /// read to its owner and describe the item from its category and tags.
  const factory TryonGarment.wardrobe({
    required final String wardrobeItemId,
  }) = TryonGarmentWardrobe;
}
