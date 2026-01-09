import 'package:tryzeon/core/product_type/domain/entities/product_type.dart';

class ProductTypeModel extends ProductType {
  const ProductTypeModel({required super.name});

  factory ProductTypeModel.fromJson(final Map<String, dynamic> json) {
    return ProductTypeModel(name: json['name_zh'] as String);
  }
}
