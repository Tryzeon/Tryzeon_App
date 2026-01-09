import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  return ProductLocalDataSource();
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

final productsProvider = FutureProvider<List<Product>>((final ref) async {
  final getProductsUseCase = ref.watch(getProductsUseCaseProvider);
  final result = await getProductsUseCase();
  if (result.isFailure) {
    throw result.getError()!;
  }
  return result.get()!;
});
