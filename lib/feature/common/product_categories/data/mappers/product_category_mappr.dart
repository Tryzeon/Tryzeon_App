import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/wardrobe_category.dart';

import '../../domain/entities/product_category.dart';
import '../collections/product_category_collection.dart';
import '../models/product_category_model.dart';
import 'product_category_mappr.auto_mappr.dart';

/// AutoMappr configuration for ProductCategory (Common module)
@AutoMappr([
  MapType<ProductCategoryModel, ProductCategory>(
    fields: [
      Field(
        'wardrobeCategory',
        custom: ProductCategoryMapprHelper.stringToWardrobeCategory,
      ),
      Field('gender', custom: ProductCategoryMapprHelper.stringToGender),
    ],
  ),
  MapType<ProductCategoryModel, ProductCategoryCollection>(
    fields: [Field('categoryId', from: 'id')],
  ),
  MapType<ProductCategoryCollection, ProductCategoryModel>(
    fields: [Field('id', from: 'categoryId')],
  ),
])
class ProductCategoryMappr extends $ProductCategoryMappr {
  const ProductCategoryMappr();
}

class ProductCategoryMapprHelper {
  static WardrobeCategory? stringToWardrobeCategory(final ProductCategoryModel source) =>
      WardrobeCategory.tryFromString(source.wardrobeCategory);

  static ProductGender stringToGender(final ProductCategoryModel source) =>
      ProductGender.tryFromString(source.gender) ?? ProductGender.unisex;
}
