import 'package:tryzeon/core/services/location_service.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/enums/product_sort_option.dart';
import 'package:typed_result/typed_result.dart';

abstract class ShopRepository {
  Future<Result<List<ShopProduct>, String>> getProducts({
    final ProductSortOption sortOption = ProductSortOption.latest,
    final String? searchQuery,
    final int? minPrice,
    final int? maxPrice,
    final Set<String>? types,
    final UserLocation? userLocation,
    final bool forceRefresh = false,
  });

  Future<Result<void, String>> incrementTryonCount(final String productId);

  Future<Result<void, String>> incrementPurchaseClickCount(final String productId);

  Future<Result<List<String>, String>> getAds({final bool forceRefresh = false});
}
