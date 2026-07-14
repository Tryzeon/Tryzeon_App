import 'package:hooks_riverpod/hooks_riverpod.dart';
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

// --- Data Sources ---
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

// --- Repository ---
@riverpod
ProductAnalyticsRepository productAnalyticsRepository(final Ref ref) {
  return ProductAnalyticsRepositoryImpl(
    remoteDataSource: ref.watch(productAnalyticsRemoteDataSourceProvider),
    localDataSource: ref.watch(productAnalyticsLocalDataSourceProvider),
  );
}

// --- Use Case ---
@riverpod
GetProductAnalyticsSummaries getProductAnalyticsSummaries(final Ref ref) {
  return GetProductAnalyticsSummaries(ref.watch(productAnalyticsRepositoryProvider));
}

// --- Feature Provider: per-product summaries ---
@riverpod
Future<List<ProductAnalyticsSummary>> productAnalyticsSummaries(final Ref ref) async {
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

/// Force refresh analytics data
Future<void> refreshAnalytics(final WidgetRef ref) async {
  try {
    final profile = await ref.read(storeProfileProvider.future);
    if (profile == null) return;

    ref.invalidate(productAnalyticsSummariesProvider);
    await ref.read(productAnalyticsSummariesProvider.future);
  } catch (e, st) {
    // Let UI show ErrorView or stale data
    AppLogger.warning('Failed to refresh analytics', e, st);
  }
}
