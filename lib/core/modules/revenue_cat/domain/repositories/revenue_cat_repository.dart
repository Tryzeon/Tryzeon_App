import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:typed_result/typed_result.dart';

abstract interface class RevenueCatRepository {
  /// A one-shot read is deliberately not offered: the customer identity is
  /// established asynchronously after startup, so a snapshot taken before that
  /// lands would report the anonymous customer's free tier and stay wrong for
  /// the rest of the session.
  ///
  /// Errors are delivered as [Failure]s on the stream.
  Stream<AppSubscriptionEntitlement> watchAppSubscriptionEntitlement();

  Future<Result<void, Failure>> logIn(final String userId);

  Future<Result<void, Failure>> logOut();
}
