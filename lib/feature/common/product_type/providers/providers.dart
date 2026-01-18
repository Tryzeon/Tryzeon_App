import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/services/isar_service.dart';
import 'package:tryzeon/feature/common/product_type/data/datasources/product_type_local_datasource.dart';
import 'package:tryzeon/feature/common/product_type/data/datasources/product_type_remote_datasource.dart';
import 'package:tryzeon/feature/common/product_type/data/repositories/product_type_repository_impl.dart';
import 'package:tryzeon/feature/common/product_type/domain/repositories/product_type_repository.dart';
import 'package:tryzeon/feature/common/product_type/domain/usecases/get_product_types.dart';
import 'package:typed_result/typed_result.dart';

// Data Sources
final productTypeRemoteDataSourceProvider = Provider<ProductTypeRemoteDataSource>((
  final ref,
) {
  return ProductTypeRemoteDataSource(Supabase.instance.client);
});

final productTypeLocalDataSourceProvider = Provider<ProductTypeLocalDataSource>((
  final ref,
) {
  final isarService = ref.watch(isarServiceProvider);
  return ProductTypeLocalDataSource(isarService);
});

// Repository
final productTypeRepositoryProvider = Provider<ProductTypeRepository>((final ref) {
  return ProductTypeRepositoryImpl(
    ref.watch(productTypeRemoteDataSourceProvider),
    ref.watch(productTypeLocalDataSourceProvider),
  );
});

// Use Cases
final getProductTypesUseCaseProvider = Provider<GetProductTypes>((final ref) {
  return GetProductTypes(ref.watch(productTypeRepositoryProvider));
});

// Providers
final productTypesProvider = FutureProvider<List<String>>((final ref) async {
  // Cache for the session duration as product types rarely change
  ref.keepAlive();

  final result = await ref.watch(getProductTypesUseCaseProvider).call();

  if (result.isSuccess) {
    return result.get()!.map((final e) => e.name).toList();
  } else {
    throw result.getError()!;
  }
});
