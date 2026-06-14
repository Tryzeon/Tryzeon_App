import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/wardrobe_category.dart';

part 'product_category.freezed.dart';

@freezed
sealed class ProductCategory with _$ProductCategory {
  const factory ProductCategory({
    required final String id,
    required final String name,

    @Default(ProductGender.unisex) final ProductGender gender,
    final WardrobeCategory? wardrobeCategory,
    final String? imageMaleUrl,
    final String? imageFemaleUrl,
  }) = _ProductCategory;

  const ProductCategory._();

  /// Whether this category should be shown to a shopper of [shopperGender].
  bool appliesTo(final ProductGender shopperGender) =>
      gender == ProductGender.unisex || gender == shopperGender;

  /// The model image to show for a given shopper [shopperGender].
  String? imageUrlFor(final ProductGender shopperGender) => switch (shopperGender) {
    ProductGender.male => imageMaleUrl,
    ProductGender.female => imageFemaleUrl,
    ProductGender.unisex => imageFemaleUrl ?? imageMaleUrl,
  };
}
