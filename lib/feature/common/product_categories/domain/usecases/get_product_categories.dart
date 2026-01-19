import 'package:tryzeon/feature/common/product_categories/domain/entities/product_category.dart';
import 'package:tryzeon/feature/common/product_categories/domain/repositories/product_category_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetProductCategories {
  GetProductCategories(this._repository);
  final ProductCategoryRepository _repository;

  Future<Result<List<ProductCategory>, String>> call() =>
      _repository.getProductCategories();
}
