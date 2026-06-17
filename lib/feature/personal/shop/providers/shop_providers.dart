import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/ad_local_datasource.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/shop_local_datasource.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/shop_remote_datasource.dart';
import 'package:tryzeon/feature/personal/shop/data/repositories/ad_repository_impl.dart';
import 'package:tryzeon/feature/personal/shop/data/repositories/product_analytics_repository_impl.dart';
import 'package:tryzeon/feature/personal/shop/data/repositories/product_repository_impl.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/ad_repository.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/product_analytics_repository.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/product_repository.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/get_ads.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/get_shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/get_shop_products.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/get_store_info.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/increment_purchase_click_count.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/increment_tryon_count.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/increment_view_count.dart';
import 'package:typed_result/typed_result.dart';

part 'shop_providers.g.dart';

// --- Data Sources ---

@riverpod
ShopRemoteDataSource shopRemoteDataSource(final Ref ref) {
  return ShopRemoteDataSource(Supabase.instance.client);
}

@riverpod
ShopLocalDataSource shopLocalDataSource(final Ref ref) {
  return ShopLocalDataSource(
    ref.watch(isarServiceProvider),
    ref.watch(cacheEntryLocalDataSourceProvider),
  );
}

@riverpod
AdLocalDataSource adLocalDataSource(final Ref ref) {
  return AdLocalDataSource();
}

// --- Repositories ---

@riverpod
ProductRepository productRepository(final Ref ref) {
  final remote = ref.watch(shopRemoteDataSourceProvider);
  final local = ref.watch(shopLocalDataSourceProvider);
  return ProductRepositoryImpl(remoteDataSource: remote, localDataSource: local);
}

@riverpod
ProductAnalyticsRepository productAnalyticsRepository(final Ref ref) {
  final analyticsQueue = ref.watch(analyticsEventQueueServiceProvider);
  return ProductAnalyticsRepositoryImpl(analyticsQueue);
}

@riverpod
AdRepository adRepository(final Ref ref) {
  final adLocal = ref.watch(adLocalDataSourceProvider);
  return AdRepositoryImpl(adLocal);
}

// --- Use Cases ---

@riverpod
GetShopProducts getShopProducts(final Ref ref) {
  return GetShopProducts(ref.watch(productRepositoryProvider));
}

@riverpod
GetShopProduct getShopProduct(final Ref ref) {
  return GetShopProduct(ref.watch(productRepositoryProvider));
}

@riverpod
GetStoreInfo getStoreInfo(final Ref ref) {
  return GetStoreInfo(ref.watch(productRepositoryProvider));
}

@riverpod
GetAds getAds(final Ref ref) {
  return GetAds(ref.watch(adRepositoryProvider));
}

@riverpod
IncrementTryonCount incrementTryonCount(final Ref ref) {
  return IncrementTryonCount(ref.watch(productAnalyticsRepositoryProvider));
}

@riverpod
IncrementViewCount incrementViewCount(final Ref ref) {
  return IncrementViewCount(ref.watch(productAnalyticsRepositoryProvider));
}

@riverpod
IncrementPurchaseClickCount incrementPurchaseClickCount(final Ref ref) {
  return IncrementPurchaseClickCount(ref.watch(productAnalyticsRepositoryProvider));
}

// --- Feature Providers ---

@riverpod
Future<List<ShopProduct>> shopProducts(final Ref ref, final ShopFilter filter) async {
  final getShopProductsUseCase = ref.watch(getShopProductsProvider);
  final result = await getShopProductsUseCase(filter: filter);
  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get()!;
}

@riverpod
Future<ShopProduct> shopProductById(final Ref ref, final String productId) async {
  final getUseCase = ref.watch(getShopProductProvider);
  final result = await getUseCase(productId);
  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get()!;
}

@riverpod
Future<List<String>> shopAds(final Ref ref) async {
  final getAdsUseCase = ref.watch(getAdsProvider);
  final result = await getAdsUseCase();
  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get()!;
}

@riverpod
Future<ShopStoreInfo> storeInfo(final Ref ref, final String storeId) async {
  final getUseCase = ref.watch(getStoreInfoProvider);
  final result = await getUseCase(storeId);
  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get()!;
}

/// 強制刷新商品列表
Future<void> refreshShopProducts(final WidgetRef ref, final ShopFilter filter) async {
  try {
    final getShopProductsUseCase = ref.read(getShopProductsProvider);
    await getShopProductsUseCase(filter: filter, forceRefresh: true);
    ref.invalidate(shopProductsProvider(filter));
    await ref.read(shopProductsProvider(filter).future);
  } catch (_) {
    // Provider 刷新失敗時，忽略異常，讓 UI 顯示 ErrorView 或舊資料
  }
}
