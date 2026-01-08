import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/shop_remote_datasource.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/shop_repository.dart';
import 'package:typed_result/typed_result.dart';

class ShopRepositoryImpl implements ShopRepository {
  ShopRepositoryImpl(this._remoteDataSource);
  final ShopRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<ShopProduct>, String>> getProducts({
    final String? searchQuery,
    final String sortBy = 'created_at',
    final bool ascending = false,
    final int? minPrice,
    final int? maxPrice,
    final Set<String>? types,
    final bool forceRefresh = false,
  }) async {
    try {
      final result = await _remoteDataSource.fetchProducts(
        searchQuery: searchQuery,
        sortBy: sortBy,
        ascending: ascending,
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
  Future<Result<void, String>> incrementPurchaseClickCount(
    final String productId,
  ) async {
    try {
      await _remoteDataSource.incrementPurchaseClickCount(productId);
      return const Ok(null);
    } catch (e) {
      AppLogger.error('記錄購買點擊失敗', e);
      return const Err('操作失敗，請稍後再試');
    }
  }
}
