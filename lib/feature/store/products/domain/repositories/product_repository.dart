import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:typed_result/typed_result.dart';

abstract class ProductRepository {
  Future<Result<List<Product>, Failure>> listProducts({
    required final String storeId,
    final bool forceRefresh = false,
  });

  Future<Result<void, Failure>> createProduct(final CreateProductParams params);

  Future<Result<Product, Failure>> getProductById(final String productId);

  Future<Result<void, Failure>> updateProduct({
    required final Product original,
    required final UpdateProductParams params,
  });

  Future<Result<void, Failure>> deleteProduct(final Product product);
}
