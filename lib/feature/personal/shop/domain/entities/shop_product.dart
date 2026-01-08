import 'package:flutter/foundation.dart';
import 'package:tryzeon/core/domain/entities/product.dart';

class ShopProduct {
  ShopProduct({
    required this.storeId,
    required this.name,
    required this.types,
    required this.price,
    required this.imagePath,
    required this.imageUrl,
    this.id,
    this.purchaseLink,
    this.tryonCount,
    this.purchaseClickCount,
    this.sizes,
    this.storeName,
    this.createdAt,
    this.updatedAt,
  });

  final String storeId;
  final String name;
  final Set<String> types;
  final double price;
  final String imagePath;
  final String imageUrl;

  final String? id;
  final String? purchaseLink;
  final int? tryonCount;
  final int? purchaseClickCount;
  final List<ProductSize>? sizes;
  final String? storeName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ShopProduct copyWith({
    final String? storeId,
    final String? name,
    final Set<String>? types,
    final double? price,
    final String? imagePath,
    final String? imageUrl,
    final String? id,
    final String? purchaseLink,
    final int? tryonCount,
    final int? purchaseClickCount,
    final List<ProductSize>? sizes,
    final String? storeName,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) {
    return ShopProduct(
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      types: types ?? this.types,
      price: price ?? this.price,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      id: id ?? this.id,
      purchaseLink: purchaseLink ?? this.purchaseLink,
      tryonCount: tryonCount ?? this.tryonCount,
      purchaseClickCount: purchaseClickCount ?? this.purchaseClickCount,
      sizes: sizes ?? this.sizes,
      storeName: storeName ?? this.storeName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> getDirtyFields(final ShopProduct target) {
    final updates = <String, dynamic>{};

    if (name != target.name) {
      updates['name'] = target.name;
    }

    if (!setEquals(types, target.types)) {
      updates['type'] = target.types.toList();
    }

    if (price != target.price) {
      updates['price'] = target.price;
    }

    if (imagePath != target.imagePath) {
      updates['image_path'] = target.imagePath;
    }

    if (purchaseLink != target.purchaseLink) {
      updates['purchase_link'] = target.purchaseLink;
    }

    return updates;
  }
}
