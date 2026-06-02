import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/clothing_style/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/measurements/entities/measurements.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/wardrobe_category.dart';
import 'package:tryzeon/feature/common/product_size/entities/product_size.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/image_item.dart';

export 'package:tryzeon/feature/common/product_size/entities/product_size.dart';

part 'product.freezed.dart';

@freezed
sealed class CreateProductSizeParams with _$CreateProductSizeParams {
  const factory CreateProductSizeParams({
    required final String name,
    final Measurements? measurements,
  }) = _CreateProductSizeParams;
}

@freezed
sealed class CreateProductParams with _$CreateProductParams {
  const factory CreateProductParams({
    required final String storeId,
    required final String name,
    required final List<String> categoryIds,
    required final double price,
    required final List<File> images,
    @Default(ProductGender.unisex) final ProductGender gender,
    final WardrobeCategory? wardrobeCategory,
    final String? purchaseLink,
    final String? material,
    final ProductElasticity? elasticity,
    final String? fit,
    final ProductThickness? thickness,
    final List<ClothingStyle>? styles,
    final List<ProductSeason>? seasons,
    final List<CreateProductSizeParams>? sizes,
  }) = _CreateProductParams;
}

@freezed
sealed class UpdateProductParams with _$UpdateProductParams {
  const factory UpdateProductParams({
    required final String productId,
    required final List<ImageItem> finalImageOrder,
    required final List<CreateProductSizeParams> sizesToAdd,
    required final List<ProductSize> sizesToUpdate,
    required final List<String> sizeIdsToDelete,
    required final String name,
    required final List<String> categoryIds,
    required final double price,
    @Default(ProductGender.unisex) final ProductGender gender,
    final WardrobeCategory? wardrobeCategory,
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
    final WardrobeCategory? wardrobeCategory,
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
