import 'package:tryzeon/feature/common/product_categories/domain/entities/product_category.dart';
import 'package:typed_result/typed_result.dart';

abstract class ProductCategoryRepository {
  Future<Result<List<ProductCategory>, String>> getProductCategories({
    final bool forceRefresh = false,
  });
}
