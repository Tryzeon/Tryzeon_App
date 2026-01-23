import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/common/product_categories/data/datasources/product_category_local_datasource.dart';
import 'package:tryzeon/feature/common/product_categories/data/datasources/product_category_remote_datasource.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/product_category.dart';
import 'package:tryzeon/feature/common/product_categories/domain/repositories/product_category_repository.dart';
import 'package:typed_result/typed_result.dart';

class ProductCategoryRepositoryImpl implements ProductCategoryRepository {
  ProductCategoryRepositoryImpl(this._remote, this._local);
  final ProductCategoryRemoteDataSource _remote;
  final ProductCategoryLocalDataSource _local;

  @override
  Future<Result<List<ProductCategory>, String>> getProductCategories({
    final bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final cached = await _local.getCached();
        if (cached != null && cached.isNotEmpty) {
          return Ok(cached);
        }
      }

      final remote = await _remote.fetchProductCategories();
      await _local.cache(remote);
      return Ok(remote);
    } catch (e, stackTrace) {
      AppLogger.error('商品類型獲取失敗', e, stackTrace);
      return const Err('無法載入商品類型，請檢查網路連線');
    }
  }
}
