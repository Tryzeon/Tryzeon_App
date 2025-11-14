import 'dart:io';
import 'package:tryzeon/feature/store/home/product/data/product_service.dart';
import 'package:tryzeon/shared/models/result.dart';

class Product {
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
  });

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
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'tryon_count': tryonCount,
      'purchase_click_count': purchaseClickCount,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      storeId: json['store_id'],
      name: json['name'],
      types: (json['type'] as List).map((e) => e.toString()).toList(),
      price: json['price'].toInt(),
      imagePath: json['image_path'],
      purchaseLink: json['purchase_link'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      tryonCount: json['tryon_count'] ?? 0,
      purchaseClickCount: json['purchase_click_count'] ?? 0,
      storeName: json['store_profile']?['store_name'],
    );
  }
}