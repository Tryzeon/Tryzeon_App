import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_category.freezed.dart';

@freezed
sealed class ProductCategory with _$ProductCategory {
  const factory ProductCategory({
    required final String id,
    required final String name,
    final String? imagePath,
    final String? imageUrl,
  }) = _ProductCategory;
}
