import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:typed_result/typed_result.dart';

abstract interface class RevenueCatRepository {
  /// Emits the entitlement state of the current RevenueCat customer, and
  /// re-emits on every change RevenueCat reports — the identity switch that
  /// follows [logIn], purchases, renewals, expirations, and changes made on
  /// another device.
  ///
  /// A one-shot read is deliberately not offered: the customer identity is
  /// established asynchronously after startup, so any single snapshot taken
  /// before that lands would report the anonymous customer's (free) tier and
  /// stay wrong for the rest of the session.
  ///
  /// Errors are delivered as [Failure]s on the stream.
  Stream<AppSubscriptionEntitlement> watchAppSubscriptionEntitlement();

  /// Logs in the given [userId] to RevenueCat (call after Supabase sign-in).
  Future<Result<void, Failure>> logIn(final String userId);

  /// Logs out of RevenueCat (call after Supabase sign-out / account deletion).
  Future<Result<void, Failure>> logOut();

  /// Restores previous purchases.
  Future<Result<AppSubscriptionEntitlement, Failure>> restorePurchases();
}
