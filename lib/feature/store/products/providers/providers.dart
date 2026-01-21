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

final productsProvider = FutureProvider.autoDispose<List<Product>>((final ref) async {
  final getProductsUseCase = ref.watch(getProductsUseCaseProvider);
  final result = await getProductsUseCase();
  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get()!;
});

/// 強制刷新商品列表，失敗時返回原始資料
Future<void> refreshProducts(final WidgetRef ref) async {
  final useCase = ref.read(getProductsUseCaseProvider);
  await useCase(forceRefresh: true);
  ref.invalidate(productsProvider);
}
