import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/ad_local_datasource.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/shop_remote_datasource.dart';
import 'package:tryzeon/feature/personal/shop/data/repositories/shop_repository_impl.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/shop_repository.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/get_ads.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/get_shop_products.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/increment_purchase_click_count.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/increment_tryon_count.dart';
import 'package:typed_result/typed_result.dart';

// --- Data Sources ---

final shopRemoteDataSourceProvider = Provider<ShopRemoteDataSource>((final ref) {
  return ShopRemoteDataSource(Supabase.instance.client);
});

final adLocalDataSourceProvider = Provider<AdLocalDataSource>((final ref) {
  return AdLocalDataSource();
});

// --- Repository ---

final shopRepositoryProvider = Provider<ShopRepository>((final ref) {
  final remote = ref.watch(shopRemoteDataSourceProvider);
  final adLocal = ref.watch(adLocalDataSourceProvider);
  return ShopRepositoryImpl(remote, adLocal);
});

// --- Use Cases ---

final getShopProductsProvider = Provider<GetShopProducts>((final ref) {
  return GetShopProducts(ref.watch(shopRepositoryProvider));
});

final getAdsProvider = Provider<GetAds>((final ref) {
  return GetAds(ref.watch(shopRepositoryProvider));
});

final incrementTryonCountProvider = Provider<IncrementTryonCount>((final ref) {
  return IncrementTryonCount(ref.watch(shopRepositoryProvider));
});

final incrementPurchaseClickCountProvider = Provider<IncrementPurchaseClickCount>((
  final ref,
) {
  return IncrementPurchaseClickCount(ref.watch(shopRepositoryProvider));
});

// --- Feature Providers ---

final shopProductsProvider = FutureProvider.family<List<ShopProduct>, ShopFilter>((
  final ref,
  final filter,
) async {
  final useCase = ref.watch(getShopProductsProvider);
  final result = await useCase(
    searchQuery: filter.searchQuery,
    sortOption: filter.sortOption,
    minPrice: filter.minPrice,
    maxPrice: filter.maxPrice,
    types: filter.types,
  );
  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get()!;
});

final shopAdsProvider = FutureProvider<List<String>>((final ref) async {
  final useCase = ref.watch(getAdsProvider);
  final result = await useCase();
  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get()!;
});

/// 強制刷新商品列表
Future<void> refreshShopProducts(final WidgetRef ref, final ShopFilter filter) async {
  try {
    final _ = await ref.refresh(shopProductsProvider(filter).future);
  } catch (_) {
    // Provider 刷新失敗時，忽略異常，讓 UI 顯示 ErrorView 或舊資料
  }
}
