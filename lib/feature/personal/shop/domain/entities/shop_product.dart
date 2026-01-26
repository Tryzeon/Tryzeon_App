import 'package:equatable/equatable.dart';

import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';

class ShopProduct extends Equatable {
  const ShopProduct({
    required this.storeInfo,
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
    this.createdAt,
    this.updatedAt,
  });

  final ShopStoreInfo storeInfo;
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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
    storeInfo,
    name,
    types,
    price,
    imagePath,
    imageUrl,
    id,
    purchaseLink,
    tryonCount,
    purchaseClickCount,
    sizes,
    createdAt,
    updatedAt,
  ];

  ShopProduct copyWith({
    final ShopStoreInfo? storeInfo,
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
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) {
    return ShopProduct(
      storeInfo: storeInfo ?? this.storeInfo,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
