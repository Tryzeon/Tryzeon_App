import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/shop_remote_datasource.dart';
import 'package:tryzeon/feature/personal/shop/data/repositories/shop_repository_impl.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/shop_repository.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/get_shop_products.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/increment_purchase_click_count.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/increment_tryon_count.dart';
import 'package:typed_result/typed_result.dart';

// --- Data Sources ---

final shopRemoteDataSourceProvider = Provider<ShopRemoteDataSource>((final ref) {
  return ShopRemoteDataSource(Supabase.instance.client);
});

// --- Repository ---

final shopRepositoryProvider = Provider<ShopRepository>((final ref) {
  final remote = ref.watch(shopRemoteDataSourceProvider);
  return ShopRepositoryImpl(remote);
});

// --- Use Cases ---

final getShopProductsProvider = Provider<GetShopProducts>((final ref) {
  return GetShopProducts(ref.watch(shopRepositoryProvider));
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
    sortBy: filter.sortBy,
    ascending: filter.ascending,
    minPrice: filter.minPrice,
    maxPrice: filter.maxPrice,
    types: filter.types,
  );
  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get()!;
});
