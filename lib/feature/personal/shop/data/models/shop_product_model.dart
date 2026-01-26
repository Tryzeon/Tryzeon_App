import 'package:tryzeon/feature/personal/shop/data/models/shop_store_info_model.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/store/products/data/models/product_model.dart';

class ShopProductModel extends ShopProduct {
  const ShopProductModel({
    required ShopStoreInfoModel super.storeInfo,
    required super.name,
    required super.types,
    required super.price,
    required super.imagePath,
    required super.imageUrl,
    super.id,
    super.purchaseLink,
    super.tryonCount,
    super.purchaseClickCount,
    super.sizes,
    super.createdAt,
    super.updatedAt,
  });

  factory ShopProductModel.fromJson(final Map<String, dynamic> json) {
    return ShopProductModel(
      storeInfo: ShopStoreInfoModel.fromJson(
        Map<String, dynamic>.from(json['store_profile']),
      ),
      name: json['name'] as String,
      types: (json['type'] as List).map((final e) => e.toString()).toSet(),
      price: (json['price'] as num).toDouble(),
      imagePath: json['image_path'] as String,
      imageUrl: json['image_url'] as String? ?? '',
      id: json['id'] as String?,
      purchaseLink: json['purchase_link'] as String?,
      tryonCount: json['tryon_count'] as int? ?? 0,
      purchaseClickCount: json['purchase_click_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      sizes:
          (json['product_sizes'] as List?)
              ?.map((final e) => ProductSizeModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }
}
