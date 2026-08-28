import 'dart:io';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'image_item.freezed.dart';

/// Unified representation of product images in the editing flow.
/// Supports both existing (already uploaded) and new (pending upload) images.
@freezed
sealed class ImageItem with _$ImageItem {
  /// An image that already exists in Supabase storage.
  const factory ImageItem.existing({
    /// Storage path (e.g., "products/abc123/image1.jpg")
    required final String path,

    /// Public URL for display
    required final String url,
  }) = ExistingImageItem;

  /// A new image selected by the user, pending upload.
  const factory ImageItem.newImage({required final File file}) = NewImageItem;
}
