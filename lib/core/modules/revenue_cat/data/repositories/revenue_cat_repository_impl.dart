import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/repositories/revenue_cat_repository.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:typed_result/typed_result.dart';

class RevenueCatRepositoryImpl implements RevenueCatRepository {
  @override
  Future<Result<AppSubscriptionEntitlement, Failure>>
  getAppSubscriptionEntitlement() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return Ok(_mapToEntitlement(customerInfo));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get RevenueCat subscription entitlement', e, stackTrace);
      return Err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> logIn(final String userId) async {
    try {
      await Purchases.logIn(userId);
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to log in to RevenueCat for user $userId', e, stackTrace);
      return Err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> logOut() async {
    try {
      await Purchases.logOut();
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to log out from RevenueCat', e, stackTrace);
      return Err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<AppSubscriptionEntitlement, Failure>> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      return Ok(_mapToEntitlement(customerInfo));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to restore RevenueCat purchases', e, stackTrace);
      return Err(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> invalidateEntitlementCache() async {
    try {
      await Purchases.invalidateCustomerInfoCache();
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to invalidate RevenueCat customer info cache',
        e,
        stackTrace,
      );
      return Err(UnknownFailure(e.toString()));
    }
  }

  AppSubscriptionEntitlement _mapToEntitlement(final CustomerInfo customerInfo) {
    final activeEntitlements = customerInfo.entitlements.active;
    final tier = _resolveTier(activeEntitlements);
    final primaryEntitlement = _getEntitlementForTier(activeEntitlements, tier);

    return AppSubscriptionEntitlement(
      tier: tier,
      expirationDate: primaryEntitlement?.expirationDate,
      productIdentifier: primaryEntitlement?.productIdentifier,
    );
  }

  AppSubscriptionTier _resolveTier(
    final Map<String, EntitlementInfo> activeEntitlements,
  ) {
    if (activeEntitlements.containsKey(AppConstants.entitlementMaxId)) {
      return AppSubscriptionTier.max;
    }

    if (activeEntitlements.containsKey(AppConstants.entitlementProId)) {
      return AppSubscriptionTier.pro;
    }

    return AppSubscriptionTier.free;
  }

  EntitlementInfo? _getEntitlementForTier(
    final Map<String, EntitlementInfo> activeEntitlements,
    final AppSubscriptionTier tier,
  ) {
    return switch (tier) {
      AppSubscriptionTier.max => activeEntitlements[AppConstants.entitlementMaxId],
      AppSubscriptionTier.pro => activeEntitlements[AppConstants.entitlementProId],
      AppSubscriptionTier.free => null,
    };
  }
}
