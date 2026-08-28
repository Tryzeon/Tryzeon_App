import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/repositories/product_repository.dart';
import 'package:typed_result/typed_result.dart';

class UpdateProduct {
  UpdateProduct(this._repository);
  final ProductRepository _repository;

  Future<Result<void, Failure>> call(final UpdateProductParams params) =>
      _repository.updateProduct(params);
}
