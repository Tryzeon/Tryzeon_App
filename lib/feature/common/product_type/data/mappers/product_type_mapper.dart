import '../collections/product_type_collection.dart';
import '../models/product_type_model.dart';

extension ProductTypeModelMapper on ProductTypeModel {
  ProductTypeCollection toCollection() {
    return ProductTypeCollection()
      ..typeId = id
      ..name = name;
  }
}

extension ProductTypeCollectionMapper on ProductTypeCollection {
  ProductTypeModel toModel() {
    return ProductTypeModel(id: typeId, name: name);
  }
}
