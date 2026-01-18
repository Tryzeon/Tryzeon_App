import 'package:tryzeon/feature/common/product_type/domain/entities/product_type.dart';

class ProductTypeModel extends ProductType {
  const ProductTypeModel({required super.id, required super.name});

  factory ProductTypeModel.fromJson(final Map<String, dynamic> json) {
    return ProductTypeModel(id: json['id'] as String, name: json['name'] as String);
  }
}
