import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:tryzeon/feature/personal/subscription/data/collections/subscription_tier_cache.dart';
import 'package:tryzeon/feature/personal/subscription/data/models/subscription_tier_model.dart';

class SubscriptionCapabilitiesLocalDataSource {
  SubscriptionCapabilitiesLocalDataSource(
    this._isarService,
    this._cacheEntryLocalDataSource,
  );

  final IsarService _isarService;
  final CacheEntryLocalDataSource _cacheEntryLocalDataSource;

  static const _mappr = PersonalMappr();
  static const _baseCacheKey = 'subscription_tier_capabilities';

  String _tierCacheKey(final String tier) => '${_baseCacheKey}_$tier';

  Future<CacheLookup<SubscriptionTierModel>> getTierCapabilities(
    final String tier,
  ) async {
    final cacheStatus = await _cacheEntryLocalDataSource.getEntryStatus(
      _tierCacheKey(tier),
      staleDuration: AppConstants.staleDurationSubscriptionTier,
    );
    if (cacheStatus == null) return const CacheMiss();
    if (cacheStatus == CacheEntryStatus.empty) return const CacheEmpty();

    final isar = await _isarService.db;
    final collection = await isar.subscriptionTierCaches.getByTier(tier);

    if (collection == null) return const CacheMiss();

    return CacheHit(
      _mappr.convert<SubscriptionTierCache, SubscriptionTierModel>(collection),
    );
  }

  Future<void> saveTierCapabilities(final SubscriptionTierModel tier) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final collection = _mappr.convert<SubscriptionTierModel, SubscriptionTierCache>(
        tier,
      );
      await isar.subscriptionTierCaches.putByTier(collection);
    });
    await _cacheEntryLocalDataSource.markHasData(_tierCacheKey(tier.id));
  }
}
