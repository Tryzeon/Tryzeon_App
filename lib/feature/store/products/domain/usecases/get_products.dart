import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/repositories/product_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetProducts {
  GetProducts(this._repository);
  final ProductRepository _repository;

  Future<Result<List<Product>, String>> call({final bool forceRefresh = false}) =>
      _repository.getProducts(forceRefresh: forceRefresh);
}
