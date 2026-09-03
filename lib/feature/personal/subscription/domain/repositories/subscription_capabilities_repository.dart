import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription_capabilities.dart';
import 'package:typed_result/typed_result.dart';

abstract interface class SubscriptionCapabilitiesRepository {
  /// Which tier the customer is on is not resolved here — it is a live value
  /// owned by the RevenueCat module, and folding it in would fix it at call
  /// time. Callers pass the tier they are currently watching.
  Future<Result<SubscriptionCapabilities, Failure>> getCapabilitiesForTier(
    final AppSubscriptionTier tier,
  );
}
