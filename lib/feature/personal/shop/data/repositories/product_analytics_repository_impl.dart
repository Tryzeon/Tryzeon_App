import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/analytics/data/services/analytics_event_queue_service.dart';
import 'package:tryzeon/core/modules/analytics/domain/entities/analytics_event.dart';
import 'package:tryzeon/core/modules/analytics/domain/entities/analytics_event_type.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/product_analytics_repository.dart';
import 'package:typed_result/typed_result.dart';

class ProductAnalyticsRepositoryImpl implements ProductAnalyticsRepository {
  ProductAnalyticsRepositoryImpl(this._analyticsQueueService);

  final AnalyticsEventQueueService _analyticsQueueService;

  @override
  Future<Result<void, Failure>> trackTryon({
    required final String productId,
    required final String storeId,
  }) async {
    try {
      _analyticsQueueService.enqueue(
        AnalyticsEvent(
          productId: productId,
          storeId: storeId,
          eventType: AnalyticsEventType.tryon,
        ),
      );
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to enqueue try-on event', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> trackView({
    required final String productId,
    required final String storeId,
  }) async {
    try {
      _analyticsQueueService.enqueue(
        AnalyticsEvent(
          productId: productId,
          storeId: storeId,
          eventType: AnalyticsEventType.view,
        ),
      );
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to enqueue view event', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> trackPurchaseClick({
    required final String productId,
    required final String storeId,
  }) async {
    try {
      _analyticsQueueService.enqueue(
        AnalyticsEvent(
          productId: productId,
          storeId: storeId,
          eventType: AnalyticsEventType.purchaseClick,
        ),
      );
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to enqueue purchase click event', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
