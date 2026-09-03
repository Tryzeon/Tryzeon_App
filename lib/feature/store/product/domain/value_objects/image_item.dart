import 'dart:io';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'image_item.freezed.dart';

@freezed
sealed class ImageItem with _$ImageItem {
  const factory ImageItem.existing({
    required final String path,
    required final String url,
  }) = ExistingImageItem;

  const factory ImageItem.newImage({required final File file}) = NewImageItem;
}
