import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:tryzeon/feature/personal/subscription/data/collections/subscription_plan_cache.dart';
import 'package:tryzeon/feature/personal/subscription/data/models/subscription_plan_model.dart';

class SubscriptionCapabilitiesLocalDataSource {
  SubscriptionCapabilitiesLocalDataSource(
    this._isarService,
    this._cacheEntryLocalDataSource,
  );

  final IsarService _isarService;
  final CacheEntryLocalDataSource _cacheEntryLocalDataSource;

  static const _mappr = PersonalMappr();
  static const _baseCacheKey = 'subscription_plan_capabilities';

  String _planCacheKey(final String planId) => '${_baseCacheKey}_$planId';

  Future<CacheLookup<SubscriptionPlanModel>> getPlanCapabilities(
    final String planId,
  ) async {
    final cacheStatus = await _cacheEntryLocalDataSource.getEntryStatus(
      _planCacheKey(planId),
      staleDuration: AppConstants.staleDurationSubscriptionPlan,
    );
    if (cacheStatus == null) return const CacheMiss();
    if (cacheStatus == CacheEntryStatus.empty) return const CacheEmpty();

    final isar = await _isarService.db;
    final collection = await isar.subscriptionPlanCaches.getByPlanId(planId);

    if (collection == null) return const CacheMiss();

    return CacheHit(
      _mappr.convert<SubscriptionPlanCache, SubscriptionPlanModel>(collection),
    );
  }

  Future<void> savePlanCapabilities(final SubscriptionPlanModel plan) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final collection = _mappr
          .convert<SubscriptionPlanModel, SubscriptionPlanCache>(plan);
      await isar.subscriptionPlanCaches.putByPlanId(collection);
    });
    await _cacheEntryLocalDataSource.markHasData(_planCacheKey(plan.id));
  }
}
