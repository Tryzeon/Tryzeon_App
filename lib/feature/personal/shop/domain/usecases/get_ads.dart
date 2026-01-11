import 'package:tryzeon/feature/personal/shop/domain/repositories/shop_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetAds {
  GetAds(this._repository);
  final ShopRepository _repository;

  Future<Result<List<String>, String>> call({final bool forceRefresh = false}) {
    return _repository.getAds(forceRefresh: forceRefresh);
  }
}
