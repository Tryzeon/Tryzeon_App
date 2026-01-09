import 'dart:io';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/repositories/product_repository.dart';
import 'package:typed_result/typed_result.dart';

class UpdateProduct {
  UpdateProduct(this._repository);
  final ProductRepository _repository;

  Future<Result<void, String>> call({
    required final Product original,
    required final Product target,
    final File? newImage,
  }) => _repository.updateProduct(original: original, target: target, newImage: newImage);
}
