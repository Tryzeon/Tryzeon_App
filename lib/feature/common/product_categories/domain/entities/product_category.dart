import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/wardrobe_category.dart';

part 'product_category.freezed.dart';

@freezed
sealed class ProductCategory with _$ProductCategory {
  const factory ProductCategory({
    required final String id,
    required final String name,
    final ProductGender? gender,
    final WardrobeCategory? wardrobeCategory,
    final String? imagePath,
    final String? imageUrl,
  }) = _ProductCategory;
}
