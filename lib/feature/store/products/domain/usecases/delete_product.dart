import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/repositories/product_repository.dart';
import 'package:typed_result/typed_result.dart';

class DeleteProduct {
  DeleteProduct(this._repository);
  final ProductRepository _repository;

  Future<Result<void, String>> call(final Product product) =>
      _repository.deleteProduct(product);
}
