import 'package:tryzeon/feature/personal/shop/domain/repositories/shop_repository.dart';
import 'package:typed_result/typed_result.dart';

class IncrementTryonCount {
  IncrementTryonCount(this._repository);
  final ShopRepository _repository;

  Future<Result<void, String>> call(final String productId) {
    return _repository.incrementTryonCount(productId);
  }
}
