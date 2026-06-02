import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/product_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetShopProducts {
  GetShopProducts(this._repository);

  final ProductRepository _repository;

  Future<Result<List<ShopProduct>, Failure>> call({
    required final ShopFilter filter,
    final bool forceRefresh = false,
  }) async {
    return _repository.getProducts(
      storeId: filter.storeId,
      searchQuery: filter.searchQuery,
      sortOption: filter.sortOption,
      minPrice: filter.minPrice,
      maxPrice: filter.maxPrice,
      categories: filter.categories,
      channels: filter.channels,
      userLocation: filter.userLocation,
      forceRefresh: forceRefresh,
    );
  }
}
