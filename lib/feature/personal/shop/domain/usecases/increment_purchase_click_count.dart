import 'package:tryzeon/feature/personal/shop/domain/repositories/shop_repository.dart';
import 'package:typed_result/typed_result.dart';

class IncrementPurchaseClickCount {
  IncrementPurchaseClickCount(this._repository);
  final ShopRepository _repository;

  Future<Result<void, String>> call(final String productId) {
    return _repository.incrementPurchaseClickCount(productId);
  }
}
