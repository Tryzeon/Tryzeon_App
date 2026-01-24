import 'package:equatable/equatable.dart';

import 'package:tryzeon/core/domain/entities/size_measurements.dart';

class ProductSize extends Equatable {
  const ProductSize({
    this.id,
    this.productId,
    required this.name,
    required this.measurements,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String? productId;
  final String name;
  final SizeMeasurements measurements;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, productId, name, measurements, createdAt, updatedAt];

  ProductSize copyWith({
    final String? id,
    final String? productId,
    final String? name,
    final SizeMeasurements? measurements,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) {
    return ProductSize(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      measurements: measurements ?? this.measurements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Product extends Equatable {
  const Product({
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

  @override
  List<Object?> get props => [
    storeId,
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
    storeName,
    createdAt,
    updatedAt,
  ];

  Product copyWith({
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
    return Product(
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
}

extension ProductListExtension on List<Product> {
  List<Product> sortProducts(final String sortBy, final bool ascending) {
    final sortedProducts = List<Product>.from(this);

    sortedProducts.sort((final a, final b) {
      int comparison;

      switch (sortBy) {
        case 'name':
          comparison = -a.name.compareTo(b.name);
          break;
        case 'price':
          comparison = a.price.compareTo(b.price);
          break;
        case 'created_at':
          comparison = (a.createdAt ?? DateTime.now()).compareTo(
            b.createdAt ?? DateTime.now(),
          );
          break;
        case 'updated_at':
          comparison = (a.updatedAt ?? DateTime.now()).compareTo(
            b.updatedAt ?? DateTime.now(),
          );
          break;
        case 'tryon_count':
          comparison = (a.tryonCount ?? 0).compareTo(b.tryonCount ?? 0);
          break;
        case 'purchase_click_count':
          comparison = (a.purchaseClickCount ?? 0).compareTo(b.purchaseClickCount ?? 0);
          break;
        default:
          comparison = 0;
      }

      return ascending ? comparison : -comparison;
    });

    return sortedProducts;
  }
}
