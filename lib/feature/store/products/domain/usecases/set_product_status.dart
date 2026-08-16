import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/repositories/product_repository.dart';
import 'package:typed_result/typed_result.dart';

class SetProductStatus {
  SetProductStatus(this._repository);
  final ProductRepository _repository;

  Future<Result<void, Failure>> call({
    required final Product product,
    required final ProductStatus status,
  }) => _repository.setProductStatus(product: product, status: status);
}
