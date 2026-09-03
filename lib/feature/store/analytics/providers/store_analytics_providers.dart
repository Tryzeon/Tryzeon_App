import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/product_analytics_local_datasource.dart';
import 'package:tryzeon/feature/store/analytics/data/datasources/product_analytics_remote_datasource.dart';
import 'package:tryzeon/feature/store/analytics/data/repositories/product_analytics_repository_impl.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/domain/repositories/product_analytics_repository.dart';
import 'package:tryzeon/feature/store/analytics/domain/usecases/get_product_analytics_summaries.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'store_analytics_providers.g.dart';

// --- Filter Provider (shared by dashboard + product cards) ---
@riverpod
class StoreAnalyticsFilter extends _$StoreAnalyticsFilter {
  @override
  ({int year, int month}) build() {
    final now = DateTime.now();
    return (year: now.year, month: now.month);
  }

  ({int year, int month}) get filter => state;

  set filter(final ({int year, int month}) filter) {
    state = filter;
  }
}

@riverpod
ProductAnalyticsRemoteDataSource productAnalyticsRemoteDataSource(final Ref ref) {
  return ProductAnalyticsRemoteDataSource(Supabase.instance.client);
}

@riverpod
ProductAnalyticsLocalDataSource productAnalyticsLocalDataSource(final Ref ref) {
  return ProductAnalyticsLocalDataSource(
    ref.watch(isarServiceProvider),
    ref.watch(cacheEntryLocalDataSourceProvider),
  );
}

@riverpod
ProductAnalyticsRepository productAnalyticsRepository(final Ref ref) {
  return ProductAnalyticsRepositoryImpl(
    remoteDataSource: ref.watch(productAnalyticsRemoteDataSourceProvider),
    localDataSource: ref.watch(productAnalyticsLocalDataSourceProvider),
  );
}

@riverpod
GetProductAnalyticsSummaries getProductAnalyticsSummaries(final Ref ref) {
  return GetProductAnalyticsSummaries(ref.watch(productAnalyticsRepositoryProvider));
}

/// Per-product analytics for the selected month, and the owner of analytics
/// refreshes.
@riverpod
class ProductAnalyticsSummariesNotifier extends _$ProductAnalyticsSummariesNotifier {
  @override
  Future<List<ProductAnalyticsSummary>> build() async {
    final profile = await ref.watch(storeProfileProvider.future);
    if (profile == null) return [];

    final filter = ref.watch(storeAnalyticsFilterProvider);
    final useCase = ref.watch(getProductAnalyticsSummariesProvider);
    final result = await useCase(
      storeId: profile.id,
      year: filter.year,
      month: filter.month,
    );

    if (result.isFailure) {
      throw result.getError()!;
    }

    return result.get()!;
  }

  /// Re-fetches the analytics summaries. Swallows errors — the provider drops
  /// into an error state and the UI shows an `ErrorView` or the previous data.
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (e, st) {
      AppLogger.warning('Failed to refresh analytics', e, st);
    }
  }
}
