import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/models/body_measurements.dart';

class ProductSize {
  ProductSize({this.id, this.productId, required this.name, required this.measurements});

  factory ProductSize.fromJson(final Map<String, dynamic> json) {
    return ProductSize(
      id: json['id'],
      productId: json['product_id'],

      name: json['name'],
      measurements: BodyMeasurements.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,

      'name': name,
      ...measurements.toJson(),
    };
  }

  final String? id;
  final String? productId;

  final String name;
  final BodyMeasurements measurements;

  ProductSize copyWith({
    final String? id,
    final String? productId,
    final String? name,
    final BodyMeasurements? measurements,
  }) {
    return ProductSize(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      measurements: measurements ?? this.measurements,
    );
  }

  /// 比對另一個 ProductSize，回傳差異的 Map
  Map<String, dynamic> getDirtyFields(final ProductSize target) {
    final updates = <String, dynamic>{};

    if (name != target.name) {
      updates['name'] = target.name;
    }

    updates.addAll(measurements.getDirtyFields(target.measurements));

    return updates;
  }
}

class Product {
  Product({
    required this.storeId,
    required this.name,
    required this.types,
    required this.price,
    required this.imagePath,

    this.id,
    this.purchaseLink,
    this.tryonCount,
    this.purchaseClickCount,
    this.sizes,
    this.storeName,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(final Map<String, dynamic> json) {
    return Product(
      storeId: json['store_id'],
      name: json['name'],
      types: (json['type'] as List).map((final e) => e.toString()).toSet(),
      price: (json['price'] as num).toDouble(),
      imagePath: json['image_path'],

      id: json['id'],
      purchaseLink: json['purchase_link'],
      tryonCount: json['tryon_count'] ?? 0,
      purchaseClickCount: json['purchase_click_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      storeName: json['store_profile']?['name'],
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

  /// 取得圖片的完整 URL (用於 CachedNetworkImage)
  String get imageUrl =>
      Supabase.instance.client.storage.from('store').getPublicUrl(imagePath);

  final String storeId;
  final String name;
  final Set<String> types;
  final double price;
  final String imagePath;

  final String? id;
  final String? purchaseLink;
  final int? tryonCount;
  final int? purchaseClickCount;
  final List<ProductSize>? sizes;
  final String? storeName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product copyWith({
    final String? storeId,
    final String? name,
    final Set<String>? types,
    final double? price,
    final String? imagePath,
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

  /// 比對另一個 Product，回傳差異的 Map (不包含 sizes)
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

/// Helper class to encapsulate product size changes
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

  /// 獲取尺寸的變更，包含新增、更新和刪除
  ProductSizeChanges getDirtyFields(final List<ProductSize>? targetSizes) {
    final originalSizes = this ?? [];
    final finalTargetSizes = targetSizes ?? [];

    final List<ProductSize> sizesToAdd = [];
    final List<Map<String, dynamic>> sizesToUpdate = [];
    final List<String> sizesToDeleteIds = [];

    // Delete
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
        // Insert
        sizesToAdd.add(targetSize);
      } else {
        // Update
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
