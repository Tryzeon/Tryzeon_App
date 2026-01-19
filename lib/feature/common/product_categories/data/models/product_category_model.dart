import 'package:tryzeon/feature/common/product_categories/domain/entities/product_category.dart';

class ProductCategoryModel extends ProductCategory {
  const ProductCategoryModel({required super.id, required super.name});

  factory ProductCategoryModel.fromJson(final Map<String, dynamic> json) {
    return ProductCategoryModel(id: json['id'] as String, name: json['name'] as String);
  }

  factory ProductCategoryModel.fromEntity(final ProductCategory entity) {
    return ProductCategoryModel(id: entity.id, name: entity.name);
  }
}
