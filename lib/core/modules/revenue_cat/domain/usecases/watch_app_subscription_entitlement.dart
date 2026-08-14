import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/repositories/revenue_cat_repository.dart';

/// Watches the current customer's entitlement.
///
/// Failures are passed through rather than folded into the free tier: a paid
/// customer must never be told they are on free because RevenueCat happened to
/// be unreachable. Callers decide how to degrade.
class WatchAppSubscriptionEntitlement {
  const WatchAppSubscriptionEntitlement(this._repository);

  final RevenueCatRepository _repository;

  Stream<AppSubscriptionEntitlement> call() {
    return _repository.watchAppSubscriptionEntitlement();
  }
}
