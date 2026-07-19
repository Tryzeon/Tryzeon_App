import 'package:tryzeon/core/error/failures.dart';
import 'package:typed_result/typed_result.dart';

/// Repository for tracking product-related analytics events.
abstract class ProductAnalyticsRepository {
  /// Tracks a try-on event for a product.
  Future<Result<void, Failure>> trackTryon({
    required final String productId,
    required final String storeId,
  });

  /// Tracks a view event for a product.
  Future<Result<void, Failure>> trackView({
    required final String productId,
    required final String storeId,
  });

  /// Tracks a purchase click event for a product.
  Future<Result<void, Failure>> trackPurchaseClick({
    required final String productId,
    required final String storeId,
  });
}
