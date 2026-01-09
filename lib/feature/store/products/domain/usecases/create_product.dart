import 'dart:io';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/repositories/product_repository.dart';
import 'package:typed_result/typed_result.dart';

class CreateProduct {
  CreateProduct(this._repository);
  final ProductRepository _repository;

  Future<Result<void, String>> call({
    required final Product product,
    required final File image,
  }) => _repository.createProduct(product: product, image: image);
}
