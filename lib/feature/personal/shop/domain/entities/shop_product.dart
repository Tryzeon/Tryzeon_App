import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/product_size.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';

part 'shop_product.freezed.dart';

@freezed
sealed class ShopProduct with _$ShopProduct {
  const factory ShopProduct({
    required final ShopStoreInfo storeInfo,
    required final String name,
    required final String categoryId,
    required final double price,
    required final List<String> imagePaths,
    required final List<String> imageUrls,
    required final String id,
    final String? purchaseLink,
    final String? material,
    final ProductElasticity? elasticity,
    final ProductFit? fit,
    final ProductThickness? thickness,
    final List<ClothingStyle>? styles,
    final List<ProductSeason>? seasons,
    final List<ProductSize>? sizes,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _ShopProduct;
}
