import 'package:tryzeon/core/services/location_service.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/enums/product_sort_option.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/shop_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetShopProducts {
  GetShopProducts(this._repository);
  final ShopRepository _repository;

  Future<Result<List<ShopProduct>, String>> call({
    final String? searchQuery,
    final ProductSortOption sortOption = ProductSortOption.latest,
    final int? minPrice,
    final int? maxPrice,
    final Set<String>? types,
    final UserLocation? userLocation,
    final bool forceRefresh = false,
  }) {
    return _repository.getProducts(
      searchQuery: searchQuery,
      sortOption: sortOption,
      minPrice: minPrice,
      maxPrice: maxPrice,
      types: types,
      userLocation: userLocation,
      forceRefresh: forceRefresh,
    );
  }
}
