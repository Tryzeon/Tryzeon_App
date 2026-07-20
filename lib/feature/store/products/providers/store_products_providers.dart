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
import 'package:tryzeon/feature/store/products/data/services/audio_recorder_service_impl.dart';
import 'package:tryzeon/feature/store/products/data/services/product_image_analyzer_impl.dart';
import 'package:tryzeon/feature/store/products/data/services/size_voice_parser.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/repositories/product_repository.dart';
import 'package:tryzeon/feature/store/products/domain/services/audio_recorder_service.dart';
import 'package:tryzeon/feature/store/products/domain/services/product_image_analyzer.dart';
import 'package:tryzeon/feature/store/products/domain/usecases/analyze_product_image.dart';
import 'package:tryzeon/feature/store/products/domain/usecases/create_product.dart';
import 'package:tryzeon/feature/store/products/domain/usecases/delete_product.dart';
import 'package:tryzeon/feature/store/products/domain/usecases/get_product.dart';
import 'package:tryzeon/feature/store/products/domain/usecases/list_products.dart';
import 'package:tryzeon/feature/store/products/domain/usecases/update_product.dart';
import 'package:tryzeon/feature/store/products/presentation/state/product_query_state.dart';
import 'package:tryzeon/feature/store/products/presentation/state/product_sort_condition.dart';
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

@riverpod
GetProduct getProductUseCase(final Ref ref) {
  return GetProduct(ref.watch(productRepositoryProvider));
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

/// Fetches all products for the store, and owns product-list refreshes.
/// Sorting is applied entirely client-side in [filteredProductsProvider].
@riverpod
class ProductsNotifier extends _$ProductsNotifier {
  @override
  Future<List<Product>> build() async {
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

  /// Force-refreshes the product list from the server. A failed store profile
  /// is re-fetched first, since the list can't be loaded without it. Swallows
  /// errors — the provider drops into an error state and the UI shows an
  /// `ErrorView` or the previous data.
  Future<void> refresh() async {
    try {
      if (ref.read(storeProfileProvider).hasError) {
        ref.invalidate(storeProfileProvider);
      }
      final profile = await ref.read(storeProfileProvider.future);
      if (profile == null) return;

      await ref.read(listProductsUseCaseProvider)(
        storeId: profile.id,
        forceRefresh: true,
      );
      ref.invalidateSelf();
      await future;
    } catch (e, st) {
      AppLogger.warning('Failed to refresh products', e, st);
    }
  }
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
      AnalyticsMetric.tryonCount => summary.tryonCount,
      AnalyticsMetric.purchaseClickCount => summary.purchaseClickCount,
    };
  }

  return filterAndSortProducts(products, query, lookup);
}

@riverpod
Future<Product> productById(final Ref ref, final String productId) async {
  final getProduct = ref.watch(getProductUseCaseProvider);
  final result = await getProduct(productId);

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

@riverpod
SizeVoiceParser sizeVoiceParser(final Ref ref) =>
    SizeVoiceParser(Supabase.instance.client);

@Riverpod(keepAlive: true)
AudioRecorderService audioRecorderService(final Ref ref) => AudioRecorderServiceImpl();

/// Which product write is currently in flight, so a form can show progress on
/// the control that started it instead of on every control at once.
enum ProductMutation { create, update, delete }

/// Owns the product create/update/delete writes: exposes which mutation is in
/// flight via [state] so a form can show progress on the right control, and
/// returns the [Result] so the caller can surface a one-shot failure message.
@riverpod
class ProductEditNotifier extends _$ProductEditNotifier {
  @override
  ProductMutation? build() => null;

  /// Creates a product for the signed-in store. Fails with an [AuthFailure]
  /// when there is no store profile to attach it to.
  Future<Result<void, Failure>> create(
    final CreateProductParams Function(String storeId) buildParams,
  ) {
    return _write(ProductMutation.create, () async {
      final storeProfile = await ref.read(storeProfileProvider.future);
      if (storeProfile == null) {
        return const Err(AuthFailure('無法獲取店家資訊，請重新登入'));
      }
      return ref.read(createProductUseCaseProvider)(buildParams(storeProfile.id));
    });
  }

  Future<Result<void, Failure>> update({
    required final Product original,
    required final UpdateProductParams params,
  }) {
    return _write(
      ProductMutation.update,
      () => ref.read(updateProductUseCaseProvider)(original: original, params: params),
    );
  }

  Future<Result<void, Failure>> delete(final Product product) {
    return _write(
      ProductMutation.delete,
      () => ref.read(deleteProductUseCaseProvider)(product),
    );
  }

  /// Runs [write] while flagging [mutation] as in flight, and drops the cached
  /// product list on success so every screen re-reads it. Kept alive for the
  /// duration, so a form popped mid-write doesn't dispose this notifier out
  /// from under the pending `state` write.
  Future<Result<void, Failure>> _write(
    final ProductMutation mutation,
    final Future<Result<void, Failure>> Function() write,
  ) async {
    final link = ref.keepAlive();
    state = mutation;
    try {
      final result = await write();
      if (result.isSuccess) {
        ref.invalidate(productsProvider);
      }
      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Product $mutation failed', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    } finally {
      state = null;
      link.close();
    }
  }
}
