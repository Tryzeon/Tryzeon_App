import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/product_category/domain/entities/product_category.dart';
import 'package:tryzeon/feature/common/product_category/domain/repositories/product_category_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetProductCategories {
  GetProductCategories(this._repository);
  final ProductCategoryRepository _repository;

  Future<Result<List<ProductCategory>, Failure>> call({
    final bool forceRefresh = false,
  }) => _repository.getProductCategories(forceRefresh: forceRefresh);
}
