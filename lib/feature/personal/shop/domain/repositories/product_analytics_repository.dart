import 'package:tryzeon/core/error/failures.dart';
import 'package:typed_result/typed_result.dart';

/// Repository for tracking product-related analytics events.
abstract class ProductAnalyticsRepository {
  Future<Result<void, Failure>> trackTryon({
    required final String productId,
    required final String storeId,
  });

  Future<Result<void, Failure>> trackView({
    required final String productId,
    required final String storeId,
  });

  Future<Result<void, Failure>> trackPurchaseClick({
    required final String productId,
    required final String storeId,
  });
}
