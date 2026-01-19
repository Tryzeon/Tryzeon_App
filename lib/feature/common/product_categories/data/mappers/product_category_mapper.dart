import '../collections/product_category_collection.dart';
import '../models/product_category_model.dart';

extension ProductCategoryModelMapper on ProductCategoryModel {
  ProductCategoryCollection toCollection() {
    return ProductCategoryCollection()
      ..categoryId = id
      ..name = name;
  }
}

extension ProductCategoryCollectionMapper on ProductCategoryCollection {
  ProductCategoryModel toModel() {
    return ProductCategoryModel(id: categoryId, name: name);
  }
}
