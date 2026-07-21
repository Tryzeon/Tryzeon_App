import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:typed_result/typed_result.dart';

abstract interface class RevenueCatRepository {
  /// Returns the current RevenueCat entitlement state for the logged-in user.
  Future<Result<AppSubscriptionEntitlement, Failure>> getAppSubscriptionEntitlement();

  /// Logs in the given [userId] to RevenueCat (call after Supabase sign-in).
  Future<Result<void, Failure>> logIn(final String userId);

  /// Logs out of RevenueCat (call after Supabase sign-out / account deletion).
  Future<Result<void, Failure>> logOut();

  /// Restores previous purchases.
  Future<Result<AppSubscriptionEntitlement, Failure>> restorePurchases();

  Future<Result<void, Failure>> invalidateEntitlementCache();
}
