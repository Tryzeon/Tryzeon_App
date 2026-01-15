import 'package:tryzeon/core/domain/entities/body_measurements.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';

class ProductSizeModel extends ProductSize {
  const ProductSizeModel({
    super.id,
    super.productId,
    required super.name,
    required super.measurements,
  });

  factory ProductSizeModel.fromJson(final Map<String, dynamic> json) {
    return ProductSizeModel(
      id: json['id'] as String?,
      productId: json['product_id'] as String?,
      name: json['name'] as String,
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
}

class ProductModel extends Product {
  const ProductModel({
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

  factory ProductModel.fromJson(final Map<String, dynamic> json) {
    return ProductModel(
      storeId: json['store_id'] as String,
      name: json['name'] as String,
      types: (json['type'] as List).map((final e) => e.toString()).toSet(),
      price: (json['price'] as num).toDouble(),
      imagePath: json['image_path'] as String,
      imageUrl: json['image_url'] as String? ?? '',
      id: json['id'] as String?,
      purchaseLink: json['purchase_link'] as String?,
      tryonCount: json['tryon_count'] as int? ?? 0,
      purchaseClickCount: json['purchase_click_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      storeName: json['store_profile']?['name'] as String?,
      sizes: (json['product_sizes'] as List?)
          ?.map((final e) => ProductSizeModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
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
      if (sizes != null)
        'product_sizes': sizes!
            .map(
              (final e) => ProductSizeModel(
                id: e.id,
                productId: e.productId,
                name: e.name,
                measurements: e.measurements,
              ).toJson(),
            )
            .toList(),
    };
  }
}
