import 'dart:io';
import 'package:tryzeon/feature/store/home/data/product_service.dart';
import 'package:tryzeon/shared/models/body_measurements.dart';
import 'package:tryzeon/shared/models/result.dart';

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
      price: json['price'].toInt(),
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
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (sizes != null) 'product_sizes': sizes,
      if (storeName != null) 'store_name': storeName,
    };
  }

  /// 按需載入圖片，使用快取機制
  Future<Result<File>> loadImage() async {
    return ProductService.getProductImage(imagePath);
  }

  final String storeId;
  final String name;
  final Set<String> types;
  final int price;
  final String imagePath;

  final String? id;
  final String? purchaseLink;
  final int? tryonCount;
  final int? purchaseClickCount;
  final List<ProductSize>? sizes;
  final String? storeName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// 比對另一個 Product，回傳差異的 Map (不包含 sizes)
  Map<String, dynamic> getDirtyFields(final Product target) {
    final updates = <String, dynamic>{};

    if (name != target.name) {
      updates['name'] = target.name;
    }

    if (types != target.types) {
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

  /// 判斷 Sizes 是否改變
  bool hasSizesChanged(final List<ProductSize>? targetSizes) {
    final currentSizes = sizes ?? [];
    final newSizes = targetSizes ?? [];

    if (currentSizes.length != newSizes.length) return true;

    for (int i = 0; i < currentSizes.length; i++) {
      final o = currentSizes[i];
      final n = newSizes[i];

      if (o.name != n.name) return true;

      // 比較測量數值
      final m1 = o.measurements.toJson();
      final m2 = n.measurements.toJson();
      for (final key in m1.keys) {
        if (m1[key] != m2[key]) return true;
      }
    }
    return false;
  }
}
