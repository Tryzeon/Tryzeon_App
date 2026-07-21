import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/repositories/revenue_cat_repository.dart';
import 'package:typed_result/typed_result.dart';

/// Forces the next entitlement read to go to the network instead of the SDK's
/// local cache. Use on an explicit user-initiated refresh — a subscription
/// changed on another device does not invalidate this device's cache.
class InvalidateEntitlementCache {
  const InvalidateEntitlementCache(this._repository);

  final RevenueCatRepository _repository;

  Future<Result<void, Failure>> call() => _repository.invalidateEntitlementCache();
}
