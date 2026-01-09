import 'package:tryzeon/core/product_type/domain/entities/product_type.dart';
import 'package:tryzeon/core/product_type/domain/repositories/product_type_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetProductTypes {
  GetProductTypes(this._repository);
  final ProductTypeRepository _repository;

  Future<Result<List<ProductType>, String>> call() => _repository.getProductTypes();
}
