import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/product_repository.dart';
import 'package:typed_result/typed_result.dart';

class ListShopProducts {
  ListShopProducts(this._repository);

  final ProductRepository _repository;

  Future<Result<List<ShopProduct>, Failure>> call({
    required final ShopFilter filter,
    final int? limit,
    final int? offset,
    final bool forceRefresh = false,
  }) async {
    return _repository.listProducts(
      storeId: filter.storeId,
      searchQuery: filter.searchQuery,
      sortOption: filter.sortOption,
      userLatitude: filter.userLatitude,
      userLongitude: filter.userLongitude,
      minPrice: filter.minPrice,
      maxPrice: filter.maxPrice,
      categories: filter.categories,
      gender: filter.gender,
      channels: filter.channels,
      materials: filter.materials,
      elasticities: filter.elasticities,
      fits: filter.fits,
      thicknesses: filter.thicknesses,
      styles: filter.styles,
      seasons: filter.seasons,
      limit: limit,
      offset: offset,
      forceRefresh: forceRefresh,
    );
  }
}
