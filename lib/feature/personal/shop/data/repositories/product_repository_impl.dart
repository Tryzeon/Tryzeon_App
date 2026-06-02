import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/location/domain/entities/user_location.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/wardrobe_category.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/shop_local_datasource.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/shop_remote_datasource.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_product_model.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_store_info_model.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/product_sort_option.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/product_repository.dart';
import 'package:typed_result/typed_result.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({
    required final ShopRemoteDataSource remoteDataSource,
    required final ShopLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final ShopRemoteDataSource _remoteDataSource;
  final ShopLocalDataSource _localDataSource;
  static const _mappr = PersonalMappr();

  @override
  Future<Result<List<ShopProduct>, Failure>> getProducts({
    final String? storeId,
    final String? searchQuery,
    final ProductSortOption sortOption = ProductSortOption.latest,
    final int? minPrice,
    final int? maxPrice,
    final Set<String>? categories,
    final Set<StoreChannel>? channels,
    final ProductGender? gender,
    final WardrobeCategory? wardrobeCategory,
    final UserLocation? userLocation,
    final bool forceRefresh = false,
  }) async {
    try {
      final result = await _remoteDataSource.getProducts(
        storeId: storeId,
        searchQuery: searchQuery,
        sortOption: sortOption,
        minPrice: minPrice,
        maxPrice: maxPrice,
        categories: categories,
        channels: channels,
        gender: gender,
        wardrobeCategory: wardrobeCategory,
        userLocation: userLocation,
      );

      // Save remote results to local cache (Write-through)
      try {
        await _localDataSource.saveProducts(result);
      } catch (e, stackTrace) {
        AppLogger.warning('Failed to save shop products to cache', e, stackTrace);
      }

      final products = _mappr.convertList<ShopProductModel, ShopProduct>(result);
      return Ok(products);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get product list', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ShopProduct, Failure>> getProduct(final String productId) async {
    try {
      // 1. Try Local Cache
      try {
        final cachedModel = await _localDataSource.getProductById(productId);
        switch (cachedModel) {
          case CacheHit<ShopProductModel>(:final data):
            return Ok(_mappr.convert<ShopProductModel, ShopProduct>(data));
          case CacheEmpty<ShopProductModel>():
          case CacheMiss<ShopProductModel>():
            break;
        }
      } catch (e, stackTrace) {
        AppLogger.warning('Shop local cache read failed', e, stackTrace);
      }

      // 2. Fallback to Remote
      final model = await _remoteDataSource.getProduct(productId);

      // 3. Update Cache
      try {
        await _localDataSource.saveProduct(model);
      } catch (e, stackTrace) {
        AppLogger.warning('Failed to save shop product to cache', e, stackTrace);
      }

      final entity = _mappr.convert<ShopProductModel, ShopProduct>(model);
      return Ok(entity);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get product by id $productId', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ShopStoreInfo, Failure>> getStoreInfo(final String storeId) async {
    try {
      final responseMap = await _remoteDataSource.getStoreProfile(storeId);
      final model = ShopStoreInfoModel.fromJson(responseMap);
      final entity = _mappr.convert<ShopStoreInfoModel, ShopStoreInfo>(model);
      return Ok(entity);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch store info for $storeId', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
