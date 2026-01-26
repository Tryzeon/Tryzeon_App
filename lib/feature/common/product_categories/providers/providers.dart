import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/feature/common/product_categories/data/datasources/product_category_local_datasource.dart';
import 'package:tryzeon/feature/common/product_categories/data/datasources/product_category_remote_datasource.dart';
import 'package:tryzeon/feature/common/product_categories/data/repositories/product_category_repository_impl.dart';
import 'package:tryzeon/feature/common/product_categories/domain/repositories/product_category_repository.dart';
import 'package:tryzeon/feature/common/product_categories/domain/usecases/get_product_categories.dart';
import 'package:typed_result/typed_result.dart';

// Data Sources
final productCategoryRemoteDataSourceProvider = Provider<ProductCategoryRemoteDataSource>(
  (final ref) {
    return ProductCategoryRemoteDataSource(Supabase.instance.client);
  },
);

final productCategoryLocalDataSourceProvider = Provider<ProductCategoryLocalDataSource>((
  final ref,
) {
  final isarService = ref.watch(isarServiceProvider);
  return ProductCategoryLocalDataSource(isarService);
});

// Repository
final productCategoryRepositoryProvider = Provider<ProductCategoryRepository>((
  final ref,
) {
  return ProductCategoryRepositoryImpl(
    ref.watch(productCategoryRemoteDataSourceProvider),
    ref.watch(productCategoryLocalDataSourceProvider),
  );
});

// Use Cases
final getProductCategoriesUseCaseProvider = Provider<GetProductCategories>((final ref) {
  return GetProductCategories(ref.watch(productCategoryRepositoryProvider));
});

// Providers
final productCategoriesProvider = FutureProvider<List<String>>((final ref) async {
  // Cache for the session duration as product categories rarely change
  ref.keepAlive();

  final result = await ref.watch(getProductCategoriesUseCaseProvider).call();

  if (result.isSuccess) {
    return result.get()!.map((final e) => e.name).toList();
  } else {
    throw result.getError()!;
  }
});
