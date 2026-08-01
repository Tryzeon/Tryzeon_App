import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/repositories/revenue_cat_repository.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/subscription/data/datasources/subscription_capabilities_local_datasource.dart';
import 'package:tryzeon/feature/personal/subscription/data/datasources/subscription_capabilities_remote_datasource.dart';
import 'package:tryzeon/feature/personal/subscription/data/models/subscription_plan_model.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription_capabilities.dart';
import 'package:tryzeon/feature/personal/subscription/domain/repositories/subscription_capabilities_repository.dart';
import 'package:typed_result/typed_result.dart';

class SubscriptionCapabilitiesRepositoryImpl
    implements SubscriptionCapabilitiesRepository {
  SubscriptionCapabilitiesRepositoryImpl({
    required final RevenueCatRepository revenueCatRepository,
    required final SubscriptionCapabilitiesRemoteDataSource remoteDataSource,
    required final SubscriptionCapabilitiesLocalDataSource localDataSource,
  }) : _revenueCatRepository = revenueCatRepository,
       _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final RevenueCatRepository _revenueCatRepository;
  final SubscriptionCapabilitiesRemoteDataSource _remoteDataSource;
  final SubscriptionCapabilitiesLocalDataSource _localDataSource;

  @override
  Future<Result<SubscriptionCapabilities, Failure>>
  getCurrentSubscriptionCapabilities() async {
    final entitlementResult = await _revenueCatRepository.getAppSubscriptionEntitlement();
    if (entitlementResult.isFailure) {
      return Err(entitlementResult.getError()!);
    }

    final entitlement = entitlementResult.get()!;
    final capabilityPlanId = _resolveCapabilityPlanId(entitlement);

    try {
      // 1. Try local cache
      try {
        final cached = await _localDataSource.getPlanCapabilities(capabilityPlanId);
        switch (cached) {
          case CacheHit<SubscriptionPlanModel>(:final data):
            return Ok(_toCapabilities(data));
          case CacheEmpty<SubscriptionPlanModel>():
          case CacheMiss<SubscriptionPlanModel>():
            break;
        }
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Local subscription plan cache read failed, falling back to remote',
          e,
          stackTrace,
        );
      }

      // 2. Fetch from remote
      final planInfo = await _remoteDataSource.getPlanCapabilities(capabilityPlanId);

      // 3. Persist to local cache
      try {
        await _localDataSource.savePlanCapabilities(planInfo);
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Failed to save subscription plan capabilities to cache',
          e,
          stackTrace,
        );
      }

      return Ok(_toCapabilities(planInfo));
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to load subscription capabilities for $capabilityPlanId',
        e,
        stackTrace,
      );
      return Err(
        ServerFailure('Failed to load subscription capabilities for $capabilityPlanId'),
      );
    }
  }

  String _resolveCapabilityPlanId(final AppSubscriptionEntitlement entitlement) {
    return switch (entitlement.tier) {
      AppSubscriptionTier.max => AppConstants.entitlementMaxId,
      AppSubscriptionTier.pro => AppConstants.entitlementProId,
      AppSubscriptionTier.free => AppConstants.entitlementFreeId,
    };
  }

  SubscriptionCapabilities _toCapabilities(final SubscriptionPlanModel planInfo) {
    return SubscriptionCapabilities(
      hasVideoAccess: planInfo.videoLimit > 0,
      wardrobeLimit: planInfo.wardrobeLimit,
      dailyTryonLimit: planInfo.tryonLimit,
      dailyChatLimit: planInfo.chatLimit,
      dailyVideoLimit: planInfo.videoLimit,
    );
  }
}
