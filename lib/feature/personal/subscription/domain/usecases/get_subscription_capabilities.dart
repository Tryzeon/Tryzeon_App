import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription_capabilities.dart';
import 'package:tryzeon/feature/personal/subscription/domain/repositories/subscription_capabilities_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetSubscriptionCapabilities {
  GetSubscriptionCapabilities(this._repository);

  final SubscriptionCapabilitiesRepository _repository;

  Future<Result<SubscriptionCapabilities, Failure>> call(
    final AppSubscriptionTier tier,
  ) {
    return _repository.getCapabilitiesForTier(tier);
  }
}
