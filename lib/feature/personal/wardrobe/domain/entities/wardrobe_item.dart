import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/wardrobe_category.dart';

part 'wardrobe_item.freezed.dart';

@freezed
sealed class CreateWardrobeItemParams with _$CreateWardrobeItemParams {
  const factory CreateWardrobeItemParams({
    required final File image,
    required final WardrobeCategory category,
    @Default([]) final List<String> tags,
  }) = _CreateWardrobeItemParams;
}

/// Domain entity representing a wardrobe item
/// Uses WardrobeCategory enum for type safety and business logic
@freezed
sealed class WardrobeItem with _$WardrobeItem {
  const factory WardrobeItem({
    required final String id,
    required final String imagePath,
    required final WardrobeCategory category,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    @Default([]) final List<String> tags,
  }) = _WardrobeItem;
}
