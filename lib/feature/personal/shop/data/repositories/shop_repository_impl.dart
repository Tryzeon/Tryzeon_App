import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/ad_local_datasource.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/shop_remote_datasource.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/enums/product_sort_option.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/shop_repository.dart';
import 'package:typed_result/typed_result.dart';

class ShopRepositoryImpl implements ShopRepository {
  ShopRepositoryImpl(this._remoteDataSource, this._adLocalDataSource);
  final ShopRemoteDataSource _remoteDataSource;
  final AdLocalDataSource _adLocalDataSource;

  @override
  Future<Result<List<ShopProduct>, String>> getProducts({
    final String? searchQuery,
    final ProductSortOption sortOption = ProductSortOption.latest,
    final int? minPrice,
    final int? maxPrice,
    final Set<String>? types,
    final bool forceRefresh = false,
  }) async {
    try {
      final result = await _remoteDataSource.fetchProducts(
        searchQuery: searchQuery,
        sortOption: sortOption,
        minPrice: minPrice,
        maxPrice: maxPrice,
        types: types,
      );
      return Ok(result);
    } catch (e) {
      AppLogger.error('商品列表獲取失敗', e);
      return const Err('無法取得商品列表，請稍後再試');
    }
  }

  @override
  Future<Result<void, String>> incrementTryonCount(final String productId) async {
    try {
      await _remoteDataSource.incrementTryonCount(productId);
      return const Ok(null);
    } catch (e) {
      AppLogger.error('記錄試穿次數失敗', e);
      return const Err('操作失敗，請稍後再試');
    }
  }

  @override
  Future<Result<void, String>> incrementPurchaseClickCount(final String productId) async {
    try {
      await _remoteDataSource.incrementPurchaseClickCount(productId);
      return const Ok(null);
    } catch (e) {
      AppLogger.error('記錄購買點擊失敗', e);
      return const Err('操作失敗，請稍後再試');
    }
  }

  @override
  Future<Result<List<String>, String>> getAds({final bool forceRefresh = false}) async {
    try {
      final ads = await _adLocalDataSource.getAdImages(forceRefresh: forceRefresh);
      return Ok(ads);
    } catch (e) {
      AppLogger.error('獲取廣告失敗', e);
      return const Err('無法獲取廣告');
    }
  }
}
