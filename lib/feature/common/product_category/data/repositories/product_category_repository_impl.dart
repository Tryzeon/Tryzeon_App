import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/common/product_category/data/datasources/product_category_local_datasource.dart';
import 'package:tryzeon/feature/common/product_category/data/datasources/product_category_remote_datasource.dart';
import 'package:tryzeon/feature/common/product_category/data/mappers/product_category_mappr.dart';
import 'package:tryzeon/feature/common/product_category/data/models/product_category_model.dart';
import 'package:tryzeon/feature/common/product_category/domain/entities/product_category.dart';
import 'package:tryzeon/feature/common/product_category/domain/repositories/product_category_repository.dart';
import 'package:typed_result/typed_result.dart';

class ProductCategoryRepositoryImpl implements ProductCategoryRepository {
  ProductCategoryRepositoryImpl(this._remoteDataSource, this._localDataSource);
  final ProductCategoryRemoteDataSource _remoteDataSource;
  final ProductCategoryLocalDataSource _localDataSource;
  static const _mappr = ProductCategoryMappr();

  @override
  Future<Result<List<ProductCategory>, Failure>> getProductCategories({
    final bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        try {
          final cachedCategories = await _localDataSource.getProductCategories();
          switch (cachedCategories) {
            case CacheHit<List<ProductCategoryModel>>(:final data):
              return Ok(_mappr.convertList<ProductCategoryModel, ProductCategory>(data));
            case CacheEmpty<List<ProductCategoryModel>>():
              return const Ok([]);
            case CacheMiss<List<ProductCategoryModel>>():
              break;
          }
        } catch (e, stackTrace) {
          AppLogger.warning(
            'Local cache read failed, falling back to remote',
            e,
            stackTrace,
          );
        }
      }

      final remoteCategories = await _remoteDataSource.getProductCategories();

      try {
        await _localDataSource.saveProductCategories(remoteCategories);
      } catch (e, stackTrace) {
        AppLogger.warning('Failed to save product categories to cache', e, stackTrace);
      }

      return Ok(
        _mappr.convertList<ProductCategoryModel, ProductCategory>(remoteCategories),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get product categories', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
