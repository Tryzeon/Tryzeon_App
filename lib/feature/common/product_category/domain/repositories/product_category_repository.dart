import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/product_category/domain/entities/product_category.dart';
import 'package:typed_result/typed_result.dart';

abstract class ProductCategoryRepository {
  Future<Result<List<ProductCategory>, Failure>> getProductCategories({
    final bool forceRefresh = false,
  });
}
