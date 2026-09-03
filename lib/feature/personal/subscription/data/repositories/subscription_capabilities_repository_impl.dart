import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/subscription/data/datasources/subscription_capabilities_local_datasource.dart';
import 'package:tryzeon/feature/personal/subscription/data/datasources/subscription_capabilities_remote_datasource.dart';
import 'package:tryzeon/feature/personal/subscription/data/models/subscription_tier_model.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription_capabilities.dart';
import 'package:tryzeon/feature/personal/subscription/domain/repositories/subscription_capabilities_repository.dart';
import 'package:typed_result/typed_result.dart';

class SubscriptionCapabilitiesRepositoryImpl
    implements SubscriptionCapabilitiesRepository {
  SubscriptionCapabilitiesRepositoryImpl({
    required final SubscriptionCapabilitiesRemoteDataSource remoteDataSource,
    required final SubscriptionCapabilitiesLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final SubscriptionCapabilitiesRemoteDataSource _remoteDataSource;
  final SubscriptionCapabilitiesLocalDataSource _localDataSource;

  @override
  Future<Result<SubscriptionCapabilities, Failure>> getCapabilitiesForTier(
    final AppSubscriptionTier tier,
  ) async {
    final capabilityTier = _resolveCapabilityTier(tier);

    try {
      // 1. Try local cache
      try {
        final cached = await _localDataSource.getTierCapabilities(capabilityTier);
        switch (cached) {
          case CacheHit<SubscriptionTierModel>(:final data):
            return Ok(_toCapabilities(data));
          case CacheEmpty<SubscriptionTierModel>():
          case CacheMiss<SubscriptionTierModel>():
            break;
        }
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Local subscription tier cache read failed, falling back to remote',
          e,
          stackTrace,
        );
      }

      // 2. Fetch from remote
      final tierConfig = await _remoteDataSource.getTierCapabilities(capabilityTier);

      // 3. Persist to local cache
      try {
        await _localDataSource.saveTierCapabilities(tierConfig);
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Failed to save subscription tier capabilities to cache',
          e,
          stackTrace,
        );
      }

      return Ok(_toCapabilities(tierConfig));
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to load subscription capabilities for $capabilityTier',
        e,
        stackTrace,
      );
      return Err(
        ServerFailure('Failed to load subscription capabilities for $capabilityTier'),
      );
    }
  }

  String _resolveCapabilityTier(final AppSubscriptionTier tier) {
    return switch (tier) {
      AppSubscriptionTier.max => AppConstants.entitlementMaxId,
      AppSubscriptionTier.pro => AppConstants.entitlementProId,
      AppSubscriptionTier.free => AppConstants.entitlementFreeId,
    };
  }

  SubscriptionCapabilities _toCapabilities(final SubscriptionTierModel tierConfig) {
    return SubscriptionCapabilities(
      hasVideoAccess: tierConfig.videoLimit > 0,
      wardrobeLimit: tierConfig.wardrobeLimit,
      dailyTryonLimit: tierConfig.tryonLimit,
      dailyChatLimit: tierConfig.chatLimit,
      dailyVideoLimit: tierConfig.videoLimit,
    );
  }
}
