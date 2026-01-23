import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/services/isar_service.dart';
import 'package:tryzeon/feature/store/products/data/datasources/product_local_datasource.dart';
import 'package:tryzeon/feature/store/products/data/datasources/product_remote_datasource.dart';
import 'package:tryzeon/feature/store/products/data/repositories/product_repository_impl.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/repositories/product_repository.dart';
import 'package:tryzeon/feature/store/products/domain/usecases/create_product.dart';
import 'package:tryzeon/feature/store/products/domain/usecases/delete_product.dart';
import 'package:tryzeon/feature/store/products/domain/usecases/get_products.dart';
import 'package:tryzeon/feature/store/products/domain/usecases/update_product.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_sort_condition.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';
import 'package:tryzeon/feature/store/profile/providers/providers.dart';
import 'package:typed_result/typed_result.dart';

final productRemoteDataSourceProvider = Provider<ProductRemoteDataSource>((final ref) {
  return ProductRemoteDataSource(Supabase.instance.client);
});

final productLocalDataSourceProvider = Provider<ProductLocalDataSource>((final ref) {
  final isarService = ref.watch(isarServiceProvider);
  return ProductLocalDataSource(isarService);
});

final productRepositoryProvider = Provider<ProductRepository>((final ref) {
  return ProductRepositoryImpl(
    remoteDataSource: ref.watch(productRemoteDataSourceProvider),
    localDataSource: ref.watch(productLocalDataSourceProvider),
  );
});

final getProductsUseCaseProvider = Provider<GetProducts>((final ref) {
  return GetProducts(ref.watch(productRepositoryProvider));
});

final createProductUseCaseProvider = Provider<CreateProduct>((final ref) {
  return CreateProduct(ref.watch(productRepositoryProvider));
});

final updateProductUseCaseProvider = Provider<UpdateProduct>((final ref) {
  return UpdateProduct(ref.watch(productRepositoryProvider));
});

final deleteProductUseCaseProvider = Provider<DeleteProduct>((final ref) {
  return DeleteProduct(ref.watch(productRepositoryProvider));
});

/// Provider for product sort condition
final productSortConditionProvider = StateProvider<SortCondition>((final ref) {
  return SortCondition.defaultSort;
});

final productsProvider = FutureProvider.autoDispose<List<Product>>((final ref) async {
  final StoreProfile? storeProfile = await ref.watch(storeProfileProvider.future);
  final String? storeId = storeProfile?.id;

  if (storeId == null) {
    throw '找不到店家資料，請先完成店家設定';
  }

  // 2. 呼叫產品 Use Case
  final sort = ref.watch(productSortConditionProvider);
  final getProductsUseCase = ref.watch(getProductsUseCaseProvider);

  final result = await getProductsUseCase(storeId: storeId, sort: sort);

  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get()!;
});

/// 強制刷新商品列表，失敗時返回原始資料
Future<void> refreshProducts(final WidgetRef ref) async {
  final storeProfile = await ref.read(storeProfileProvider.future);
  final storeId = storeProfile?.id;
  if (storeId == null) return;

  final sort = ref.read(productSortConditionProvider);
  final useCase = ref.read(getProductsUseCaseProvider);

  await useCase(storeId: storeId, sort: sort, forceRefresh: true);
  ref.invalidate(productsProvider);
}
