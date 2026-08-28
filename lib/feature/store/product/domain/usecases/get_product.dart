import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/repositories/product_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetProduct {
  GetProduct(this._repository);
  final ProductRepository _repository;

  Future<Result<Product, Failure>> call(final String productId) =>
      _repository.getProductById(productId);
}
