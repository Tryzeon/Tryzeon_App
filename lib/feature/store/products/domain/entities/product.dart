import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/measurements/domain/entities/measurements.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/product_size.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/size_item.dart';

export 'package:tryzeon/feature/common/product_size/domain/entities/product_size.dart';

part 'product.freezed.dart';

@freezed
sealed class CreateProductParams with _$CreateProductParams {
  const factory CreateProductParams({
    required final String storeId,
    required final String name,
    required final List<String> categoryIds,
    required final double price,
    required final List<File> images,
    required final List<NewSizeItem> sizes,
    @Default(ProductGender.unisex) final ProductGender gender,
    final String? purchaseLink,
    final String? material,
    final ProductElasticity? elasticity,
    final String? fit,
    final ProductThickness? thickness,
    final List<ClothingStyle>? styles,
    final List<ProductSeason>? seasons,
  }) = _CreateProductParams;
}

@freezed
sealed class UpdateProductParams with _$UpdateProductParams {
  const factory UpdateProductParams({
    required final String productId,
    required final List<ImageItem> finalImageOrder,

    /// The full list of sizes the product should end up with. The data layer
    /// diffs it against the product's current sizes.
    required final List<SizeItem> sizes,
    required final String name,
    required final List<String> categoryIds,
    required final double price,
    @Default(ProductGender.unisex) final ProductGender gender,
    final String? purchaseLink,
    final String? material,
    final ProductElasticity? elasticity,
    final String? fit,
    final ProductThickness? thickness,
    final List<ClothingStyle>? styles,
    final List<ProductSeason>? seasons,
  }) = _UpdateProductParams;
}

@freezed
sealed class Product with _$Product {
  const factory Product({
    required final String storeId,
    required final String name,
    required final List<String> categoryIds,
    required final double price,
    required final List<String> imagePaths,
    required final List<String> imageUrls,
    required final String id,
    @Default(ProductGender.unisex) final ProductGender gender,
    final String? purchaseLink,
    final String? material,
    final ProductElasticity? elasticity,
    final String? fit,
    final ProductThickness? thickness,
    final List<ClothingStyle>? styles,
    final List<ProductSeason>? seasons,
    final List<ProductSize>? sizes,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _Product;
}
