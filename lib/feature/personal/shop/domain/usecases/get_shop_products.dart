import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/shop_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetShopProducts {
  GetShopProducts(this._repository);
  final ShopRepository _repository;

  Future<Result<List<ShopProduct>, String>> call({
    final String? searchQuery,
    final String sortBy = 'created_at',
    final bool ascending = false,
    final int? minPrice,
    final int? maxPrice,
    final Set<String>? types,
    final bool forceRefresh = false,
  }) {
    return _repository.getProducts(
      searchQuery: searchQuery,
      sortBy: sortBy,
      ascending: ascending,
      minPrice: minPrice,
      maxPrice: maxPrice,
      types: types,
      forceRefresh: forceRefresh,
    );
  }
}
