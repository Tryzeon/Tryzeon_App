import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/repositories/product_repository.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/image_item.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/size_item.dart';
import 'package:typed_result/typed_result.dart';

class UpdateProduct {
  UpdateProduct(this._repository);
  final ProductRepository _repository;

  Future<Result<void, Failure>> call({
    required final Product original,
    required final Product target,
    required final List<ImageItem> targetImages,
    required final List<SizeItem> targetSizes,
  }) {
    return _repository.updateProduct(
      original: original,
      target: target,
      targetImages: targetImages,
      targetSizes: targetSizes,
    );
  }
}
