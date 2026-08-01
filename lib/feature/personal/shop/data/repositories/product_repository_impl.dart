import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/shop_remote_datasource.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_product_model.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_store_info_model.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_sort.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/product_repository.dart';
import 'package:typed_result/typed_result.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({required final ShopRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final ShopRemoteDataSource _remoteDataSource;
  static const _mappr = PersonalMappr();

  @override
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
  }) async {
    try {
      final result = await _remoteDataSource.listProducts(
        storeId: storeId,
        searchQuery: searchQuery,
        sort: sort,
        minPrice: minPrice,
        maxPrice: maxPrice,
        categories: categories,
        channels: channels,
        gender: gender,
        materials: materials,
        elasticities: elasticities,
        fits: fits,
        thicknesses: thicknesses,
        styles: styles,
        seasons: seasons,
        limit: limit,
        offset: offset,
      );

      return Ok(_mappr.convertList<ShopProductModel, ShopProduct>(result));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get product list', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<ShopProduct, Failure>> getProduct(final String productId) async {
    try {
      final model = await _remoteDataSource.getProduct(productId);
      return Ok(_mappr.convert<ShopProductModel, ShopProduct>(model));
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
