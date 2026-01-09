import 'dart:io';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:typed_result/typed_result.dart';

abstract class ProductRepository {
  Future<Result<List<Product>, String>> getProducts();

  Future<Result<void, String>> createProduct({
    required final Product product,
    required final File image,
  });

  Future<Result<void, String>> updateProduct({
    required final Product original,
    required final Product target,
    final File? newImage,
  });

  Future<Result<void, String>> deleteProduct(final Product product);
}
