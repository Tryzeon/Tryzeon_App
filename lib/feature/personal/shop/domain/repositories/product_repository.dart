import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/product_sort_option.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:typed_result/typed_result.dart';

/// Repository for product query operations.
abstract class ProductRepository {
  /// Fetches a list of products based on the provided filters.
  Future<Result<List<ShopProduct>, Failure>> getProducts({
    final String? storeId,
    final ProductSortOption sortOption = ProductSortOption.latest,
    final String? searchQuery,
    final int? minPrice,
    final int? maxPrice,
    final Set<String>? categories,
    final Set<StoreChannel>? channels,
    final ProductGender? gender,
    final String? material,
    final Set<ProductElasticity>? elasticities,
    final Set<String>? fits,
    final Set<ProductThickness>? thicknesses,
    final Set<String>? styles,
    final Set<ProductSeason>? seasons,
    final int? limit,
    final int? offset,
    final bool forceRefresh = false,
  });

  /// Fetches a single product by its ID.
  Future<Result<ShopProduct, Failure>> getProduct(final String productId);

  /// Fetches store profile by storeId.
  Future<Result<ShopStoreInfo, Failure>> getStoreInfo(final String storeId);
}
