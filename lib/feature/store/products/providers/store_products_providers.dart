import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/data/services/image_analysis_api.dart';
import 'package:tryzeon/core/data/services/store_images_api_provider.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/analytics/domain/entities/product_analytics_summary.dart';
import 'package:tryzeon/feature/store/analytics/providers/store_analytics_providers.dart';
import 'package:tryzeon/feature/store/products/data/datasources/product_local_datasource.dart';
import 'package:tryzeon/feature/store/products/data/datasources/product_remote_datasource.dart';
import 'package:tryzeon/feature/store/products/data/repositories/product_repository_impl.dart';
import 'package:tryzeon/feature/store/products/data/services/product_image_analyzer_impl.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/repositories/product_repository.dart';
import 'package:tryzeon/feature/store/products/domain/services/product_image_analyzer.dart';
import 'package:tryzeon/feature/store/products/domain/usecases/analyze_product_image.dart';
import 'package:tryzeon/feature/store/products/domain/usecases/create_product.dart';
import 'package:tryzeon/feature/store/products/domain/usecases/delete_product.dart';
import 'package:tryzeon/feature/store/products/domain/usecases/list_products.dart';
import 'package:tryzeon/feature/store/products/domain/usecases/update_product.dart';
import 'package:tryzeon/feature/store/products/presentation/state/product_query_state.dart';
import 'package:tryzeon/feature/store/products/presentation/state/product_sort_condition.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'store_products_providers.g.dart';

@riverpod
ProductRemoteDataSource productRemoteDataSource(final Ref ref) {
  return ProductRemoteDataSource(
    Supabase.instance.client,
    ref.watch(storeImagesApiProvider),
  );
}

@riverpod
ProductLocalDataSource productLocalDataSource(final Ref ref) {
  final isarService = ref.watch(isarServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  final cacheEntryLocalDataSource = ref.watch(cacheEntryLocalDataSourceProvider);
  return ProductLocalDataSource(isarService, cacheService, cacheEntryLocalDataSource);
}

@riverpod
ProductRepository productRepository(final Ref ref) {
  return ProductRepositoryImpl(
    remoteDataSource: ref.watch(productRemoteDataSourceProvider),
    localDataSource: ref.watch(productLocalDataSourceProvider),
  );
}

@riverpod
ListProducts listProductsUseCase(final Ref ref) {
  return ListProducts(productRepository: ref.watch(productRepositoryProvider));
}

@riverpod
CreateProduct createProductUseCase(final Ref ref) {
  return CreateProduct(ref.watch(productRepositoryProvider));
}

@riverpod
UpdateProduct updateProductUseCase(final Ref ref) {
  return UpdateProduct(ref.watch(productRepositoryProvider));
}

@riverpod
DeleteProduct deleteProductUseCase(final Ref ref) {
  return DeleteProduct(ref.watch(productRepositoryProvider));
}

/// Manages the combined search, filter, and sort state for store products.
@riverpod
class ProductQuery extends _$ProductQuery {
  @override
  ProductQueryState build() => const ProductQueryState();

  void updateSearch(final String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateSort(final SortCondition sort) {
    state = state.copyWith(sort: sort);
  }

  void reset() => state = const ProductQueryState();
}

/// Fetches all products for the store. Sorting is applied entirely client-side
/// in [filteredProductsProvider].
@riverpod
Future<List<Product>> products(final Ref ref) async {
  final profile = await ref.watch(storeProfileProvider.future);
  if (profile == null || profile.id.isEmpty) {
    throw const UnknownFailure('Store profile not found');
  }

  final listProductsUseCase = ref.watch(listProductsUseCaseProvider);
  final result = await listProductsUseCase(storeId: profile.id);

  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get()!;
}

/// Applies search and sort (incl. analytics-based sort) entirely in memory.
@riverpod
Future<List<Product>> filteredProducts(final Ref ref) async {
  final products = await ref.watch(productsProvider.future);
  final query = ref.watch(productQueryProvider);

  final analyticsAsync = ref.watch(productAnalyticsSummariesProvider);
  final summaries = analyticsAsync.when(
    data: (final v) => v,
    loading: () => const <ProductAnalyticsSummary>[],
    error: (final e, final st) {
      AppLogger.warning('Analytics summaries unavailable for sort', e, st);
      return const <ProductAnalyticsSummary>[];
    },
  );
  final byId = {for (final s in summaries) s.productId: s};

  int lookup(final String productId, final AnalyticsMetric metric) {
    final summary = byId[productId];
    if (summary == null) return 0;
    return switch (metric) {
      AnalyticsMetric.viewCount => summary.viewCount,
      AnalyticsMetric.tryOnCount => summary.tryonCount,
      AnalyticsMetric.purchaseClickCount => summary.purchaseClickCount,
    };
  }

  return filterAndSortProducts(products, query, lookup);
}

@riverpod
Future<Product> productById(final Ref ref, final String productId) async {
  final repository = ref.watch(productRepositoryProvider);
  final result = await repository.getProductById(productId);

  if (result.isFailure) {
    throw result.getError()!;
  }

  return result.get()!;
}

@riverpod
ProductImageAnalyzer productImageAnalyzer(final Ref ref) =>
    ProductImageAnalyzerImpl(ref.watch(imageAnalysisApiProvider));

@Riverpod(keepAlive: true)
AnalyzeProductImage analyzeProductImageUseCase(final Ref ref) =>
    AnalyzeProductImage(ref.watch(productImageAnalyzerProvider));

/// 強制刷新商品列表
/// 注意：此函數會吞掉 refresh 時的異常，確保 ErrorView 的 onRetry 能正常運作
Future<void> refreshProducts(final WidgetRef ref) async {
  StoreProfile? profile;
  try {
    if (ref.read(storeProfileProvider).hasError) {
      ref.invalidate(storeProfileProvider);
    }
    profile = await ref.read(storeProfileProvider.future);
  } catch (_) {
    return;
  }

  if (profile == null) return;

  final listProductsUseCase = ref.read(listProductsUseCaseProvider);

  try {
    await listProductsUseCase(storeId: profile.id, forceRefresh: true);
    ref.invalidate(productsProvider);
    await ref.read(productsProvider.future);
  } catch (_) {
    // Provider 刷新失敗時，忽略異常，讓 UI 顯示 ErrorView 或舊資料
  }
}
