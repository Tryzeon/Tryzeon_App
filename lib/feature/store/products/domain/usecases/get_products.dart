import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/repositories/product_repository.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_sort_condition.dart';
import 'package:typed_result/typed_result.dart';

class GetProducts {
  GetProducts(this._repository);
  final ProductRepository _repository;

  Future<Result<List<Product>, String>> call({
    required final String storeId,
    final SortCondition sort = SortCondition.defaultSort,
    final bool forceRefresh = false,
  }) => _repository.getProducts(storeId: storeId, sort: sort, forceRefresh: forceRefresh);
}
