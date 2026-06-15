import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/feature/common/product_categories/data/datasources/product_category_local_datasource.dart';
import 'package:tryzeon/feature/common/product_categories/data/datasources/product_category_remote_datasource.dart';
import 'package:tryzeon/feature/common/product_categories/data/repositories/product_category_repository_impl.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/product_category.dart';
import 'package:tryzeon/feature/common/product_categories/domain/repositories/product_category_repository.dart';
import 'package:tryzeon/feature/common/product_categories/domain/usecases/get_product_categories.dart';
import 'package:typed_result/typed_result.dart';

part 'product_categories_providers.g.dart';

@riverpod
ProductCategoryRemoteDataSource productCategoryRemoteDataSource(final Ref ref) {
  return ProductCategoryRemoteDataSource(Supabase.instance.client);
}

@riverpod
ProductCategoryLocalDataSource productCategoryLocalDataSource(final Ref ref) {
  final isarService = ref.watch(isarServiceProvider);
  final cacheEntryLocalDataSource = ref.watch(cacheEntryLocalDataSourceProvider);
  return ProductCategoryLocalDataSource(isarService, cacheEntryLocalDataSource);
}

@riverpod
ProductCategoryRepository productCategoryRepository(final Ref ref) {
  return ProductCategoryRepositoryImpl(
    ref.watch(productCategoryRemoteDataSourceProvider),
    ref.watch(productCategoryLocalDataSourceProvider),
  );
}

@riverpod
GetProductCategories getProductCategoriesUseCase(final Ref ref) {
  return GetProductCategories(ref.watch(productCategoryRepositoryProvider));
}

@riverpod
Future<List<ProductCategory>> productCategories(final Ref ref) async {
  final result = await ref.watch(getProductCategoriesUseCaseProvider).call();

  if (result.isSuccess) {
    return result.get()!;
  } else {
    throw result.getError()!;
  }
}
