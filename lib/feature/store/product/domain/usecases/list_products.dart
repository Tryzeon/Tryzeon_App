import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/repositories/product_repository.dart';
import 'package:typed_result/typed_result.dart';

class ListProducts {
  ListProducts({required final ProductRepository productRepository})
    : _productRepository = productRepository;

  final ProductRepository _productRepository;

  Future<Result<List<Product>, Failure>> call({
    required final String storeId,
    final bool forceRefresh = false,
  }) async {
    return _productRepository.listProducts(storeId: storeId, forceRefresh: forceRefresh);
  }
}
