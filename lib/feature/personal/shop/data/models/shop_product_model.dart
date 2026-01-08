import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/shared/models/product.dart';

class ShopProductModel extends ShopProduct {
  ShopProductModel({
    required super.storeId,
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
    super.storeName,
    super.createdAt,
    super.updatedAt,
  });

  factory ShopProductModel.fromJson(final Map<String, dynamic> json) {
    final imagePath = json['image_path'] as String;
    return ShopProductModel(
      storeId: json['store_id'] as String,
      name: json['name'] as String,
      types: (json['type'] as List).map((final e) => e.toString()).toSet(),
      price: (json['price'] as num).toDouble(),
      imagePath: imagePath,
      imageUrl: Supabase.instance.client.storage.from('store').getPublicUrl(imagePath),
      id: json['id'] as String?,
      purchaseLink: json['purchase_link'] as String?,
      tryonCount: json['tryon_count'] as int? ?? 0,
      purchaseClickCount: json['purchase_click_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      storeName: json['store_profile']?['name'] as String?,
      sizes:
          (json['product_sizes'] as List?)
              ?.map((final e) => ProductSize.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'store_id': storeId,
      'name': name,
      'type': types.toList(),
      'price': price,
      'image_path': imagePath,
      if (id != null) 'id': id,
      if (purchaseLink != null) 'purchase_link': purchaseLink,
      if (tryonCount != null) 'tryon_count': tryonCount,
      if (purchaseClickCount != null) 'purchase_click_count': purchaseClickCount,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (sizes != null) 'product_sizes': sizes!.map((final e) => e.toJson()).toList(),
      if (storeName != null) 'store_name': storeName,
    };
  }
}
