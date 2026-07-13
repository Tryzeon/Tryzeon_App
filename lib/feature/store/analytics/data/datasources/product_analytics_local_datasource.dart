import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/feature/store/analytics/data/collections/product_analytics_cache.dart';
import 'package:tryzeon/feature/store/analytics/data/models/product_analytics_summary_model.dart';
import 'package:tryzeon/feature/store/data/mappers/store_mappr.dart';

class ProductAnalyticsLocalDataSource {
  ProductAnalyticsLocalDataSource(this._isarService, this._cacheEntryLocalDataSource);

  final IsarService _isarService;
  final CacheEntryLocalDataSource _cacheEntryLocalDataSource;
  static const _mappr = StoreMappr();

  static String cacheKeyForMonth(final String storeId, final int year, final int month) =>
      'product_analytics:$storeId:$year:$month';

  Future<CacheLookup<List<ProductAnalyticsSummaryModel>>> getProductAnalyticsSummaries(
    final String storeId,
    final int year,
    final int month,
  ) async {
    final isar = await _isarService.db;
    final cacheKey = cacheKeyForMonth(storeId, year, month);
    final cacheStatus = await _cacheEntryLocalDataSource.getEntryStatus(cacheKey);
    if (cacheStatus == null) return const CacheMiss();

    if (cacheStatus == CacheEntryStatus.empty) {
      return const CacheEmpty();
    }

    final collections = await isar.productAnalyticsCaches
        .filter()
        .storeIdEqualTo(storeId)
        .yearEqualTo(year)
        .monthEqualTo(month)
        .findAll();

    if (collections.isEmpty) return const CacheMiss();

    return CacheHit(
      collections
          .map(
            (final c) =>
                _mappr.convert<ProductAnalyticsCache, ProductAnalyticsSummaryModel>(c),
          )
          .toList(),
    );
  }

  Future<void> saveProductAnalyticsSummaries(
    final String storeId,
    final int year,
    final int month,
    final List<ProductAnalyticsSummaryModel> summaries,
  ) async {
    final isar = await _isarService.db;
    final cacheKey = cacheKeyForMonth(storeId, year, month);

    await isar.writeTxn(() async {
      for (final summary in summaries) {
        final collection = _mappr
            .convert<ProductAnalyticsSummaryModel, ProductAnalyticsCache>(summary);

        final existing = await isar.productAnalyticsCaches
            .filter()
            .storeIdEqualTo(summary.storeId)
            .productIdEqualTo(summary.productId)
            .yearEqualTo(summary.year)
            .monthEqualTo(summary.month)
            .findFirst();

        if (existing != null) {
          collection.id = existing.id;
        }

        await isar.productAnalyticsCaches.put(collection);
      }
    });
    await _cacheEntryLocalDataSource.markListState(cacheKey, isEmpty: summaries.isEmpty);
  }

  Future<void> markProductAnalyticsSummariesEmpty(
    final String storeId,
    final int year,
    final int month,
  ) async {
    await _cacheEntryLocalDataSource.markEmpty(cacheKeyForMonth(storeId, year, month));
  }
}
