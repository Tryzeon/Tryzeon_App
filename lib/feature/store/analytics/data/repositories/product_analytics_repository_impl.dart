import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/product_analytics_local_datasource.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/product_analytics_remote_datasource.dart';
import 'package:tryzeon/feature/store/analytics/data/models/product_analytics_summary_model.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/domain/repositories/product_analytics_repository.dart';
import 'package:tryzeon/feature/store/data/mappers/store_mappr.dart';
import 'package:typed_result/typed_result.dart';

class ProductAnalyticsRepositoryImpl implements ProductAnalyticsRepository {
  ProductAnalyticsRepositoryImpl({
    required final ProductAnalyticsRemoteDataSource remoteDataSource,
    required final ProductAnalyticsLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final ProductAnalyticsRemoteDataSource _remoteDataSource;
  final ProductAnalyticsLocalDataSource _localDataSource;
  static const _mappr = StoreMappr();

  @override
  Future<Result<List<ProductAnalyticsSummary>, Failure>> getProductAnalyticsSummaries(
    final String storeId, {
    final int? year,
    final int? month,
  }) async {
    try {
      final now = DateTime.now();
      final isAllTime = year == null || month == null;

      if (isAllTime) {
        final models = await _remoteDataSource.getAllProductAnalyticsSummaries(storeId);
        return Ok(_aggregateByProduct(models));
      }

      final isPastMonth = year < now.year || (year == now.year && month < now.month);

      if (isPastMonth) {
        final cached = await _localDataSource.getProductAnalyticsSummaries(
          storeId,
          year,
          month,
        );
        switch (cached) {
          case CacheHit<List<ProductAnalyticsSummaryModel>>(:final data):
            return Ok(
              data
                  .map(
                    (final m) => _mappr
                        .convert<ProductAnalyticsSummaryModel, ProductAnalyticsSummary>(
                          m,
                        ),
                  )
                  .toList(),
            );
          case CacheEmpty<List<ProductAnalyticsSummaryModel>>():
            return const Ok([]);
          case CacheMiss<List<ProductAnalyticsSummaryModel>>():
            break;
        }
      }

      final remoteModels = await _remoteDataSource.getProductAnalyticsSummaries(
        storeId,
        year: year,
        month: month,
      );

      if (isPastMonth) {
        if (remoteModels.isEmpty) {
          await _localDataSource.markProductAnalyticsSummariesEmpty(storeId, year, month);
        } else {
          await _localDataSource.saveProductAnalyticsSummaries(
            storeId,
            year,
            month,
            remoteModels,
          );
        }
      }

      return Ok(
        remoteModels
            .map(
              (final m) => _mappr
                  .convert<ProductAnalyticsSummaryModel, ProductAnalyticsSummary>(m),
            )
            .toList(),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get product analytics summaries', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  List<ProductAnalyticsSummary> _aggregateByProduct(
    final List<ProductAnalyticsSummaryModel> models,
  ) {
    final Map<String, ProductAnalyticsSummary> map = {};
    for (final m in models) {
      final existing = map[m.productId];
      if (existing != null) {
        map[m.productId] = ProductAnalyticsSummary(
          productId: m.productId,
          viewCount: existing.viewCount + m.viewCount,
          tryonCount: existing.tryonCount + m.tryonCount,
          purchaseClickCount: existing.purchaseClickCount + m.purchaseClickCount,
        );
      } else {
        map[m.productId] = ProductAnalyticsSummary(
          productId: m.productId,
          viewCount: m.viewCount,
          tryonCount: m.tryonCount,
          purchaseClickCount: m.purchaseClickCount,
        );
      }
    }
    return map.values.toList();
  }
}
