import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:tryzeon/core/domain/entities/body_measurements.dart';

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
  final BodyMeasurements measurements;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, productId, name, measurements, createdAt, updatedAt];

  ProductSize copyWith({
    final String? id,
    final String? productId,
    final String? name,
    final BodyMeasurements? measurements,
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

  Map<String, dynamic> getDirtyFields(final ProductSize target) {
    final updates = <String, dynamic>{};

    if (name != target.name) {
      updates['name'] = target.name;
    }

    updates.addAll(measurements.getDirtyFields(target.measurements));

    return updates;
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

  Map<String, dynamic> getDirtyFields(final Product target) {
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

class ProductSizeChanges {
  ProductSizeChanges({
    required this.toAdd,
    required this.toUpdate,
    required this.toDeleteIds,
  });

  final List<ProductSize> toAdd;
  final List<Map<String, dynamic>> toUpdate;
  final List<String> toDeleteIds;

  bool get hasChanges =>
      toAdd.isNotEmpty || toUpdate.isNotEmpty || toDeleteIds.isNotEmpty;
}

extension ProductSizeListExtension on List<ProductSize>? {
  ProductSize? firstWhereOrNull(final bool Function(ProductSize) test) {
    if (this == null) return null;
    for (final element in this!) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }

  ProductSizeChanges getDirtyFields(final List<ProductSize>? targetSizes) {
    final originalSizes = this ?? [];
    final finalTargetSizes = targetSizes ?? [];

    final List<ProductSize> sizesToAdd = [];
    final List<Map<String, dynamic>> sizesToUpdate = [];
    final List<String> sizesToDeleteIds = [];

    final targetSizeIds = finalTargetSizes
        .map((final s) => s.id)
        .whereType<String>()
        .toSet();
    for (final originalSize in originalSizes) {
      if (originalSize.id != null && !targetSizeIds.contains(originalSize.id)) {
        sizesToDeleteIds.add(originalSize.id!);
      }
    }

    for (final targetSize in finalTargetSizes) {
      if (targetSize.id == null) {
        sizesToAdd.add(targetSize);
      } else {
        final originalSize = originalSizes.firstWhereOrNull(
          (final s) => s.id == targetSize.id,
        );
        if (originalSize != null) {
          final dirtyFields = originalSize.getDirtyFields(targetSize);
          if (dirtyFields.isNotEmpty) {
            sizesToUpdate.add({'id': targetSize.id!, 'dirtyFields': dirtyFields});
          }
        }
      }
    }

    return ProductSizeChanges(
      toAdd: sizesToAdd,
      toUpdate: sizesToUpdate,
      toDeleteIds: sizesToDeleteIds,
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
