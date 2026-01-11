import 'package:tryzeon/feature/common/product_type/domain/entities/product_type.dart';
import 'package:typed_result/typed_result.dart';

abstract class ProductTypeRepository {
  Future<Result<List<ProductType>, String>> getProductTypes();
}
