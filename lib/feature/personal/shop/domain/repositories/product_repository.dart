import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_sort.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:typed_result/typed_result.dart';

/// Repository for product query operations.
abstract class ProductRepository {
  /// Fetches a list of products based on the provided filters.
  Future<Result<List<ShopProduct>, Failure>> listProducts({
    final String? storeId,
    final String? searchQuery,
    final ShopSort sort = const ShopSort.latest(),
    final int? minPrice,
    final int? maxPrice,
    final Set<String>? categories,
    final Set<StoreChannel>? channels,
    final ProductGender? gender,
    final Set<String>? materials,
    final Set<ProductElasticity>? elasticities,
    final Set<ProductFit>? fits,
    final Set<ProductThickness>? thicknesses,
    final Set<ClothingStyle>? styles,
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
