import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/product_size.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/size_item.dart';

export 'package:tryzeon/feature/common/product_size/domain/entities/product_size.dart';

part 'product.freezed.dart';

@freezed
sealed class ProductDraft with _$ProductDraft {
  const factory ProductDraft({
    required final String name,
    required final String categoryId,
    required final double price,
    @Default(ProductGender.unisex) final ProductGender gender,
    final String? purchaseLink,
    final String? material,
    final ProductElasticity? elasticity,
    final ProductFit? fit,
    final ProductThickness? thickness,
    final Set<ClothingStyle>? styles,
    final Set<ProductSeason>? seasons,
  }) = _ProductDraft;
}

@freezed
sealed class CreateProductParams with _$CreateProductParams {
  const factory CreateProductParams({
    required final String storeId,
    required final ProductDraft draft,
    required final List<File> images,
    required final List<NewSizeItem> sizes,
  }) = _CreateProductParams;
}

@freezed
sealed class UpdateProductParams with _$UpdateProductParams {
  const factory UpdateProductParams({
    required final Product original,
    required final ProductDraft draft,
    required final List<ImageItem> images,
    required final List<SizeItem> sizes,
  }) = _UpdateProductParams;
}

@freezed
sealed class Product with _$Product {
  const factory Product({
    required final String storeId,
    required final String name,
    required final String categoryId,
    required final double price,
    required final List<String> imagePaths,
    required final List<String> imageUrls,
    required final String id,
    @Default(ProductStatus.active) final ProductStatus status,
    @Default(ProductGender.unisex) final ProductGender gender,
    final String? purchaseLink,
    final String? material,
    final ProductElasticity? elasticity,
    final ProductFit? fit,
    final ProductThickness? thickness,
    final Set<ClothingStyle>? styles,
    final Set<ProductSeason>? seasons,
    final List<ProductSize>? sizes,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _Product;
}

extension ProductApplyDraft on Product {
  Product applyDraft(final ProductDraft draft) => copyWith(
    name: draft.name,
    categoryId: draft.categoryId,
    price: draft.price,
    gender: draft.gender,
    purchaseLink: draft.purchaseLink,
    material: draft.material,
    elasticity: draft.elasticity,
    fit: draft.fit,
    thickness: draft.thickness,
    styles: draft.styles,
    seasons: draft.seasons,
  );
}
