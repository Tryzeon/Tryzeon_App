import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:typed_result/typed_result.dart';

abstract class ShopRepository {
  Future<Result<List<ShopProduct>, String>> getProducts({
    final String? searchQuery,
    final String sortBy = 'created_at',
    final bool ascending = false,
    final int? minPrice,
    final int? maxPrice,
    final Set<String>? types,
    final bool forceRefresh = false,
  });

  Future<Result<void, String>> incrementTryonCount(final String productId);

  Future<Result<void, String>> incrementPurchaseClickCount(final String productId);
}
