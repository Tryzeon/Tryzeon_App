import 'dart:io';
import 'package:tryzeon/feature/store/home/data/product_service.dart';
import 'package:tryzeon/shared/models/body_measurements.dart';
import 'package:tryzeon/shared/models/result.dart';

class ProductSize {
  ProductSize({
    this.id,
    this.productId,
    required this.name,
    required this.measurements,
  });

  factory ProductSize.fromJson(final Map<String, dynamic> json) {
    return ProductSize(
      id: json['id'],
      productId: json['product_id'],
      name: json['name'] ?? '',
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
    this.id,
    required this.storeId,
    required this.name,
    required this.types,
    required this.price,
    required this.imagePath,
    required this.purchaseLink,
    this.createdAt,
    this.updatedAt,
    this.tryonCount = 0,
    this.purchaseClickCount = 0,
    this.storeName,
    this.sizes = const [],
  });

  factory Product.fromJson(final Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      storeId: json['store_id'],
      name: json['name'],
      types: (json['type'] as List).map((final e) => e.toString()).toList(),
      price: json['price'].toInt(),
      imagePath: json['image_path'],
      purchaseLink: json['purchase_link'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      tryonCount: json['tryon_count'] ?? 0,
      purchaseClickCount: json['purchase_click_count'] ?? 0,
      storeName: json['store_profile']?['store_name'],
      sizes:
          (json['product_sizes'] as List?)
              ?.map((final e) => ProductSize.fromJson(e))
              .toList() ??
          [],
    );
  }
  final String? id;
  final String storeId;
  final String name;
  final List<String> types;
  final int price;
  final String imagePath;
  final String purchaseLink;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int tryonCount;
  final int purchaseClickCount;
  final String? storeName;
  final List<ProductSize> sizes;

  /// 按需載入圖片，使用快取機制
  Future<Result<File>> loadImage() async {
    return ProductService.loadProductImage(imagePath);
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'store_id': storeId,
      'name': name,
      'type': types,
      'price': price,
      'image_path': imagePath,
      'purchase_link': purchaseLink,
      'created_at':
          createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updated_at':
          updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'tryon_count': tryonCount,
      'purchase_click_count': purchaseClickCount,
    };
  }
}
